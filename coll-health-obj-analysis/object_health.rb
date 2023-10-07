require 'json'
require 'yaml'
require 'uc3-ssm'
require 'optparse'
require_relative 'object_health_db'
require_relative 'object_health_tests'

class ObjectHealth
  def initialize(argv)
    @options = make_options(argv)
    puts @options
    config_file = 'config/database.ssm.yml'
    @config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: config_file, resolve_key: 'default', return_key: 'default')
    @obj_health_db = ObjectHealthDb.new(@config)
    @obj_health_tests = ObjectHealthTests.new(@config)
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
    File.open("#{ENV['COLLHDATA']}/objects_details.ndjson", 'a') do |f|
      f.write(obj.to_json)
      f.write("\n")
    end
  end

  def processObject(id)
    obj = nil
    if @options[:build_objects]
      puts "build #{id}"
      obj = @obj_health_db.build_object(id)
      @obj_health_db.update_object(id, obj)
    else
      puts "get #{id}"
      obj = @obj_health_db.get_object(id)
    end

    if @options[:test_objects]
      puts "test #{id}"
      obj = @obj_health_tests.run_tests(obj)
    end

    if @options[:build_objects] || @options[:test_objects]
      puts "export #{id}"
      export_object(obj)
    end

    if @options[:debug]
      puts obj
    end
  end
end

oh = ObjectHealth.new(ARGV)
oh.processObjects