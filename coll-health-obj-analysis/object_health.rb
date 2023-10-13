require 'json'
require 'yaml'
require 'uc3-ssm'
require 'optparse'
require_relative 'object_health_db'
require_relative 'object_health_tests'
require_relative 'analysis_tasks'

class ObjectHealth
  def initialize(argv)
    @collhdata = ENV.fetch('COLLHDATA', ENV['PWD'])
    @options = make_options(argv)
    @debug = {export_count: 0, export_max: 5, print_count: 0, print_max: 1}
    puts @options
    config_file = 'config/database.ssm.yml'
    @config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: config_file, resolve_key: 'default', return_key: 'default')
    @obj_health_db = ObjectHealthDb.new(@config)
    @analysis_tasks = AnalysisTasks.new(self, @config)
    @obj_health_tests = ObjectHealthTests.new(self, @config)
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

  def export_object(obj)
    File.open("#{@collhdata}/objects_details.ndjson", 'a') do |f|
      f.write(obj.to_json)
      f.write("\n")
    end
    if @options[:debug]
      if @debug[:export_count] < @debug[:export_max]
        File.open("#{@collhdata}/objects_details.#{obj[:id]}.json", 'a') do |f|
          f.write(JSON.pretty_generate(obj))
        end
        @debug[:export_count] += 1
        puts @debug
      end
    end
  end

  def processObject(id)
    obj = nil
    if @options[:build_objects]
      puts "build #{id}"
      obj = @obj_health_db.build_object(id)
    else
      puts "get #{id}"
      obj = @obj_health_db.get_object(id)
    end

    if @options[:analyze_objects] && !obj.nil?
      puts "analyze #{id}"
      obj = @analysis_tasks.run_tasks(obj)
    end

    if @options[:test_objects] && !obj.nil?
      puts "test #{id}"
      obj = @obj_health_tests.run_tests(obj)
    end

    if !obj.nil? && (@options[:build_objects] || @options[:test_objects] || @options[:analysis_tasks])
      puts "save #{id}"
      @obj_health_db.update_object(id, obj)
      puts "export #{id}"
      export_object(obj)
    end

    if @options[:debug]
      if @debug[:print_count] < @debug[:print_max]
        puts JSON.pretty_generate(obj)
        @debug[:print_count] += 1
      end
    end
  end
end

oh = ObjectHealth.new(ARGV)
oh.processObjects