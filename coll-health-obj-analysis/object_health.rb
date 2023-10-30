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
require_relative 'oh_object_component'

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
    config_file = 'config/database.ssm.yml'
    @config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: config_file, resolve_key: 'default', return_key: 'default')
    @options = make_options(argv)
    @debug = {
      export_count: 0, 
      export_max: @config.fetch('debug', {}).fetch('export_max', 5), 
      print_count: 0, 
      print_max: @config.fetch('debug', {}).fetch('print_max', 1)
    }
    @obj_health_db = ObjectHealthDb.new(@config, mode, @options[:query_params])
    @analysis_tasks = AnalysisTasks.new(self, @config)
    @obj_health_tests = ObjectHealthTests.new(self, @config)
    @opensrch = ObjectHealthOpenSearch.new(self, @config)
    now = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    @colltax_mnemonics = {}
    @colltax_patterns = {}
    @config.fetch(:collection_taxonomy.to_s, {}).each do |colltax,conf|
      next if conf.nil?
      conf.fetch(:patterns.to_s, []).each do |p|
        @colltax_patterns[p] = colltax
      end
      conf.fetch(:mnemonics.to_s, []).each do |m|
        @colltax_mnemonics[m] = colltax
      end
    end
  end

  def self.status_values
    [:SKIP, :PASS, :INFO, :WARN, :FAIL]
  end

  def self.status_val(status)
    self.status_values.each_with_index do |v,i|
      return i if v == status
    end
    0
  end

  def self.compare_state(ostate, status)
    ObjectHealth.status_val(ostate) < ObjectHealth.status_val(status) ? status : ostate
  end

  def collection_taxonomy(mnemonic)
    m = mnemonic
    @colltax_patterns.each do |k,colltax|
      if mnemonic =~ Regexp.new(k)
        m = colltax
        break
      end
    end
    @colltax_mnemonics.each do |k,colltax|
      if k == mnemonic
        m = colltax
        break
      end
    end
    m
  end

  def make_options(argv)
    options = {query_params: {}}
    @config.fetch('default-params', {}).each do |k,v|
      options[:query_params][k.to_sym] = v
    end
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
      opts.on('--clear-build', 'Clear Build Records') do
        options[:clear_build] = true
      end
      opts.on('--clear-analysis', 'Clear Analysis Records') do
        options[:clear_analysis] = true
      end
      opts.on('--clear-tests', 'Clear Tests Records') do
        options[:clear_tests] = true
      end
      # The following values may be edited into yaml queries... perform some sanitization on the values
      opts.on('--query=QUERY', 'Object Selection Query to Use') do |n|
        options[:query_params][:QUERY] = n.gsub(%r[[^A-Za-z0-9_\-]], "")
      end
      opts.on('--mnemonic=MNEMONIC', 'Set Query Param Mnemonic') do |n|
        options[:query_params][:MNEMONIC] = n.gsub(%r[[^a-z0-9_\-]], "")
      end
      opts.on('--limit=LIMIT', 'Set Query Limit') do |n|
        options[:query_params][:LIMIT] = n.to_i
      end
    end.parse(ARGV)
    options    
  end

  def preliminary_tasks
    puts @options
    @obj_health_db.clear_object_health(:build) if @options[:clear_build]
    @obj_health_db.clear_object_health(:analysis) if @options[:clear_analysis]
    @obj_health_db.clear_object_health(:tests) if @options[:clear_tests]
  end

  def process_objects
    @obj_health_db.get_object_list.each do |id|
      process_object(id)
    end
  end

  def export_object(ohobj)
    if @options[:debug]
      if @debug[:export_count] < @debug[:export_max]
        File.open("#{@collhdata}/debug/objects_details.#{ohobj.id}.json", 'w') do |f|
          f.write(ohobj.build.pretty_json)
        end
        @debug[:export_count] += 1
        puts @debug
      end
    end
    @opensrch.export(ohobj)
  end

  def process_object(id)
    ohobj = ObjectHealthObject.new(id)
    ohobj.init_components
    if @options[:build_objects]
      puts "build #{id}"
      @obj_health_db.build_object(ohobj)
      puts "save #{id}"
      @obj_health_db.update_object_build(ohobj)
    else
      puts "get #{id}"
      @obj_health_db.load_object_json(ohobj)
    end

    if @options[:analyze_objects] && ohobj.build.loaded?
      puts "  analyze #{id}"
      @analysis_tasks.run_tasks(ohobj)
      @obj_health_db.update_object_analysis(ohobj)
    end

    if @options[:test_objects] && ohobj.build.loaded?
      puts "  test #{id}"
      @obj_health_tests.run_tests(ohobj)
      @obj_health_db.update_object_tests(ohobj)
    end

    if ohobj.build.loaded? && (@options[:build_objects] || @options[:test_objects] || @options[:analyze_objects])
      puts "  export #{id}"
      begin
        export_object(ohobj)
      rescue => e 
        puts "Export failed #{e}"
      end
    end

    if @options[:debug]
      if @debug[:print_count] < @debug[:print_max]
        puts ohobj.build.pretty_json
        @debug[:print_count] += 1
      end
    end
  end

  def mode
    return :build if @options[:build_objects]
    return :analysis if @options[:analyze_objects]
    return :tests if @options[:test_objects]
    return :na
  end
end

oh = ObjectHealth.new(ARGV)
oh.preliminary_tasks
oh.process_objects