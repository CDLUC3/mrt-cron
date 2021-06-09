require 'yaml'
require 'aws-sdk-lambda'

class ConsistencyDriver
    def initialize(mode)
        @config = YAML.load_file('reports.yml')
        region = ENV['AWS_REGION'] || 'us-west-2'
        @mode = mode

        @admintool = get_func_name("admintool", @mode)
        @colladmin = get_func_name("colladmin", @mode)
        @lambda = Aws::Lambda::Client.new(
            region: region, 
            http_read_timeout: 180
        )
        puts @admintool
        puts @colladmin
    end

    def get_func_name(key, suffix)
        val = @config.fetch(key, {}).fetch("function", "na")
        "#{val}-#{suffix}"
    end

    def invoke_lambda(arn, params)
        begin
            resp = @lambda.invoke({
                function_name: arn, 
                payload: params.to_json 
            })
            # payload is serialized json
            payload = JSON.parse(resp.payload.read)
            # Body of the response is serialized
            rj = JSON.parse(payload.fetch("body", {}.to_json))
            rpt = rj.fetch("report_path","n/a")
            puts("\t#{resp.status_code}\t#{rpt}")
        rescue => e
            puts("\t#{e.message}")
        end
        sleep 2
    end

    def run (path)
        @config.fetch("admintool", {}).fetch("daily", []).each do |query|
            next unless path.empty? || path == query.fetch('path', '')
            puts "#{query}"
            invoke_lambda(@admintool, query)
        end
        @config.fetch("colladmin", {}).fetch("daily", []).each do |query|
            next unless path.empty? || path == query.fetch('path', '')
            puts "#{query}"
            invoke_lambda(@colladmin, query)
        end
    end
end

puts ARGV
defenv = ENV.fetch('SSM_ROOT_PATH', 'dev').split('/')[-1]
driver = ConsistencyDriver.new(
    ARGV.length > 0 ? ARGV[0] : defenv
)
driver.run(ARGV.length > 1 ? ARGV[1] : '')