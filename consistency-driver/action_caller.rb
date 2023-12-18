# frozen_string_literal: true

require 'yaml'
require 'aws-sdk-lambda'
require 'uc3-ssm'

# bundle exec raction_caller.rb label
#   if domain is empty, the SSM_ROOT_PATH is utilized
#   if report-path is empty, all reports are run

# Invoke lambda for a specific AdminTool Query for CollectionAdmin Task
class ActionCaller
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
        puts 'Usage: ruby action_caller.rb label'
      else
        pos.push(s)
      end
    end
    @mode = ENV.fetch('SSM_ROOT_PATH', 'dev').split('/')[-1]
    @label = pos.length.positive? ? pos[0] : ''
  end

  def initialize(args = [])
    @debug = false
    @status = 'PASS'
    do_args(args)
    @output = []
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
      output(rj)
      rpt = rj.fetch('report_path', 'n/a')
      output("\t#{resp.status_code}\t#{rpt}")
    rescue StandardError => e
      @status = 'ERROR'
      output("\t#{e.message}")
    end
    sleep 2
  end

  def run
    @config.fetch('admintool', {}).fetch('actions', []).each do |query|
      next unless @label == query.fetch('label', 'n/a')

      output(query.to_s)
      invoke_lambda(@admintool, query)
    end
    @config.fetch('colladmin', {}).fetch('actions', []).each do |query|
      next unless @label == query.fetch('label', 'n/a')

      output(query.to_s)
      invoke_lambda(@colladmin, query)
    end
  end
end

driver = ActionCaller.new(ARGV)
driver.run
