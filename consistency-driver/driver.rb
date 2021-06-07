require 'yaml'
require 'aws-sdk-lambda'
require "base64"

class ConsistencyDriver
    def initialize(mode)
        @config = YAML.load_file('reports.yml')
        region = ENV['AWS_REGION'] || 'us-west-2'
        @mode = mode
        @tmpfile = "/tmp/adminrpt.#{@mode}.txt"

        @admintool = get_func_name("admintool", @mode)
        @colladmin = get_func_name("colladmin", @mode)
        @lambda = Aws::Lambda::Client.new(region: region)
        puts @admintool
        puts @colladmin
    end

    def get_func_name(key, suffix)
        val = @config.fetch("admintool", {}).fetch("function", "na")
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

    def run 
        @config.fetch("admintool", {}).fetch("daily", []).each do |query|
            puts "#{query}"
            invoke_lambda(@admintool, query)
        end
        @config.fetch("colladmin", {}).fetch("daily", []).each do |query|
            puts "#{query}"
            invoke_lambda(@colladmin, query)
        end
    end
end

puts ARGV
driver = ConsistencyDriver.new(
    ARGV.length > 0 ? ARGV[0] : 'dev'
)
driver.run