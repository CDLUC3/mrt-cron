require 'json'
require 'yaml'
require 'uc3-ssm'
require 'optparse'
require 'opensearch'
require 'time'
require_relative 'object_health_db'
require_relative 'object_health_tests'
require_relative 'object_health_opensearch'
require_relative 'analysis_tasks'
require_relative 'oh_object'

# Inputs
# - Merritt Inventory Database
# - Configuration Yaml
# - TBD: Periodic Queries (rebuilt weekly by cron) 
#   - Duplicate Checksum File 
#   - Median File Size for mime type
# - TBD: Bitstream Analysis Processes
#   - Should output go to RDS or to S3? (inv_object_id, inv_file_id, analysis_name, analysis_date, analysis_status, analysis_result)
#
# Outputs
# - Merritt Billing Database (working storage for object json)
# - OpenSearch

class ObjectHealth
  def initialize(argv)
    @collhdata = ENV.fetch('COLLHDATA', ENV['PWD'])
    @options = make_options(argv)
    puts @options
    config_file = 'config/database.ssm.yml'
    @config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: config_file, resolve_key: 'default', return_key: 'default')
    @debug = {
      export_count: 0, 
      export_max: @config.fetch('debug', {}).fetch('export_max', 5), 
      print_count: 0, 
      print_max: @config.fetch('debug', {}).fetch('print_max', 1)
    }
    @obj_health_db = ObjectHealthDb.new(@config)
    @analysis_tasks = AnalysisTasks.new(self, @config)
    @obj_health_tests = ObjectHealthTests.new(self, @config)
    @opensrch = ObjectHealthOpenSearch.new(self, @config)
    now = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    @dt_build = @config.fetch('config-dateime', {}).fetch('build', now)
    @dt_analysis = @config.fetch('config-dateime', {}).fetch('analysis', now)
    @dt_tests = @config.fetch('config-dateime', {}).fetch('tests', now)
  end

  def self.status_values
    [:SKIP, :PASS, :INFO, :WARN, :FAIL]
  end

  def make_options(argv)
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby object_health.rb [--help] [--build] [--test]"
      opts.on('-h', '--help', 'Show help and exit') do
        puts opts
        exit(0)
      end
      opts.on('-b', '--build', 'Build Objects') do
        options[:build_objects] = true
      end
      opts.on('-a', '--analyze', 'Analyze Objects') do
        options[:analyze_objects] = true
      end
      opts.on('-t', '--test', 'Test Objects') do
        options[:test_objects] = true
      end
      opts.on('-d', '--debug', 'Debug') do
        options[:debug] = true
      end
    end.parse(ARGV)
    options    
  end

  def processObjects
    @obj_health_db.get_object_list.each do |id|
      processObject(id)
    end
  end

  def export_object(ohobj)
    if @options[:debug]
      if @debug[:export_count] < @debug[:export_max]
        File.open("#{@collhdata}/objects_details.#{ohobj.id}.json", 'w') do |f|
          f.write(ohobj.pretty_json)
        end
        @debug[:export_count] += 1
        puts @debug
      end
    end
    @opensrch.export(ohobj)
  end

  def processObject(id)
    ohobj = ObjectHealthObject.new(id)
    if @options[:build_objects]
      puts "build #{id}"
      @obj_health_db.build_object(ohobj)
      puts "save #{id}"
      @obj_health_db.update_object_build(ohobj)
    else
      puts "get #{id}"
      @obj_health_db.load_object_json(ohobj)
    end

    if @options[:analyze_objects] && ohobj.loaded?
      puts "analyze #{id}"
      @analysis_tasks.run_tasks(ohobj)
      @obj_health_db.update_object_analysis(ohobj)
    end

    if @options[:test_objects] && ohobj.loaded?
      puts "test #{id}"
      @obj_health_tests.run_tests(ohobj)
      @obj_health_db.update_object_tests(ohobj)
    end

    if ohobj.loaded? && (@options[:build_objects] || @options[:test_objects] || @options[:analysis_tasks])
      puts "export #{id}"
      begin
        export_object(ohobj)
      rescue => e 
        puts "Export failed #{e}"
      end
    end

    if @options[:debug]
      if @debug[:print_count] < @debug[:print_max]
        puts JSON.pretty_generate(ohobj.get_build)
        @debug[:print_count] += 1
      end
    end
  end
end

oh = ObjectHealth.new(ARGV)
oh.processObjects