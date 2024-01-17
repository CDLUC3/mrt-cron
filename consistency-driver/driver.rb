# frozen_string_literal: true

require 'yaml'
require 'aws-sdk-lambda'
require 'uc3-ssm'

# bundle exec ruby driver.sh [-debug] [domain] [report-path]
#   if domain is empty, the SSM_ROOT_PATH is utilized
#   if report-path is empty, all reports are run

# Merritt Admin Tool consistency driver - call a select set of AdminTool Queries and
# CollectionAdmin Tasks on a daily basis
class ConsistencyDriver
  def output(str)
    @output.push(str)
    puts(str) if @debug
  end

  def do_args(args)
    pos = []
    args.each do |s|
      case s
      when '-debug'
        @debug = true
      when 'help'
        puts 'Usage: ruby driver.rb [-debug] [mode] [report-path]'
      else
        pos.push(s)
      end
    end
    @mode = pos.length.positive? ? pos[0] : ENV.fetch('SSM_ROOT_PATH', 'dev').split('/')[-1]
    @path = pos.length > 1 ? pos[1] : ''
  end

  def initialize(args = [])
    @debug = false
    @status = 'PASS'
    do_args(args)
    @output = []
    # @config = YAML.load_file('reports.yml')
    @config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: 'reports.yml')

    region = ENV.fetch('AWS_REGION', 'us-west-2')
    @siteurl = @config.fetch('admintool', {}).fetch('siteurl', 'https://merritt.cdlib.org')
    @admintool = get_func_name('admintool', @mode)
    @colladmin = get_func_name('colladmin', @mode)
    @lambda = Aws::Lambda::Client.new(
      region: region,
      http_read_timeout: 180
    )
    output(@siteurl)
    output(@admintool)
    output(@colladmin)
  end

  def get_func_name(key, suffix)
    val = @config.fetch(key, {}).fetch('function', 'na')
    "#{val}-#{suffix}"
  end

  def record_status(rpt)
    return if @status == 'ERROR'

    suff = rpt.split('.')[-1]
    @status = 'FAIL' if suff == 'FAIL'
    return if @status == 'FAIL'

    @status = 'WARN' if suff == 'WARN'
    return if @status == 'WARN'

    @status = 'INFO' if suff == 'INFO'
  end

  def invoke_lambda(arn, params)
    begin
      resp = @lambda.invoke({
        function_name: arn,
        payload: params.to_json,
        client_context: Base64.strict_encode64({
          # Only custom, client, and env are passed: https://github.com/aws/aws-sdk-js/issues/1388
          custom: {
            context_code: @config.fetch('context', '')
          }
        }.to_json)
      })
      # payload is serialized json
      payload = JSON.parse(resp.payload.read)
      # Body of the response is serialized
      rj = JSON.parse(payload.fetch('body', {}.to_json))
      rpt = rj.fetch('report_path', 'n/a')
      output("\t#{resp.status_code}\t#{rpt}")
      record_status(rpt)
    rescue StandardError => e
      @status = 'ERROR'
      output("\t#{e.message}")
    end
    sleep 2
  end

  def run
    @config.fetch('admintool', {}).fetch('daily', []).each do |query|
      next unless @path.empty? || @path == query.fetch('path', '')

      output(query.to_s)
      invoke_lambda(@admintool, query)
    end
    @config.fetch('colladmin', {}).fetch('daily', []).each do |query|
      next unless @path.empty? || @path == query.fetch('path', '')

      output(query.to_s)
      invoke_lambda(@colladmin, query)
    end
    d = `date "+%Y-%m-%d"`.chop
    msg = "#{@siteurl}?path=report&report=consistency-reports/#{d}"
    subj = "#{@status.upcase}: #{@mode} Consistency Report for #{d}"
    `echo "#{msg}" | mail -r uc3@cdlib.org -s "#{subj}" #{@config.fetch('email', 'dpr2')}`
  end
end

driver = ConsistencyDriver.new(ARGV)
driver.run
