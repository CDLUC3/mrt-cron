require 'yaml'
require 'aws-sdk-lambda'

class ConsistencyDriver
    def output(s)
        @output.push(s)
        puts(s) if @debug
    end

    def do_args(args)
        pos = []
        args.each do |s|
            if s == "-debug"
                @debug = true
            elsif s == "help"
                puts "Usage: ruby driver.rb [-debug] [mode] [report-path]"
            else
                pos.append(s)                
            end
        end
        @mode = pos.length > 0 ? pos[0] : ENV.fetch('SSM_ROOT_PATH', 'dev').split('/')[-1]
        @path = pos.length > 1 ? pos[1] : ''
    end

    def initialize(args = [])
        @debug = false
        do_args(args)
        @output = []
        @config = YAML.load_file('reports.yml')
        region = ENV['AWS_REGION'] || 'us-west-2'

        @admintool = get_func_name("admintool", @mode)
        @colladmin = get_func_name("colladmin", @mode)
        @lambda = Aws::Lambda::Client.new(
            region: region, 
            http_read_timeout: 180
        )
        output(@admintool)
        output(@colladmin)
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
            output("\t#{resp.status_code}\t#{rpt}")
        rescue => e
            output("\t#{e.message}")
        end
        sleep 2
    end

    def run
        @config.fetch("admintool", {}).fetch("daily", []).each do |query|
            next unless @path.empty? || @path == query.fetch('path', '')
            output("#{query}")
            invoke_lambda(@admintool, query)
        end
        @config.fetch("colladmin", {}).fetch("daily", []).each do |query|
            next unless @path.empty? || @path == query.fetch('path', '')
            output("#{query}")
            invoke_lambda(@colladmin, query)
        end
        %x{ mail -s "" 'hello....' }
    end
end

driver = ConsistencyDriver.new(ARGV)
driver.run