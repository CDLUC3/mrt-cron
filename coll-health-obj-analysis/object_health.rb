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
# only on dev box for now
#require 'debug'

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
    config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: config_file, resolve_key: 'default', return_key: 'default')
    @config = JSON.parse(config.to_json, symbolize_names: true)
    # map mnemonics to groups
    @mnemonics = {}
    # map collection taxonomy groups to mnemonics
    @ct_groups = {}
    load_collection_taxonomy
    $options = make_options(argv)
    @debug = {
      export_count: 0, 
      export_max: @config.fetch(:debug, {}).fetch(:export_max, 5), 
      print_count: 0, 
      print_max: @config.fetch(:debug, {}).fetch(:print_max, 1)
    }
    $options[:query_params][:SKIPS] = @ct_groups[:tag_skip].map{|s| "'#{s}'"}.join(",")
    @obj_health_db = ObjectHealthDb.new(@config, mode, $options[:query_params], $options[:iterative_params], @mnemonics)
    @analysis_tasks = AnalysisTasks.new(self, @config)
    @obj_health_tests = ObjectHealthTests.new(self, @config)
    @build_config = @config.fetch(:build_config, {})
    @opensrch = ObjectHealthOpenSearch.new(self, @config)
    now = Time.now.strftime("%Y-%m-%d %H:%M:%S")
  end

  def load_collection_taxonomy
    @config.fetch(:collection_taxonomy, []).each do |ctdef|
      next if ctdef.nil?
      ctdef.fetch(:groups, {}).keys.each do |g|
        ctdef.fetch(:mnemonics, {}).each do |m, mdef|
          @mnemonics[m] = [] unless @mnemonics.key?(m)
          @mnemonics[m].append(g)
          @ct_groups[g] = [] unless @ct_groups.key?(g)
          @ct_groups[g].append(m)
          next if mdef.nil?
          mdef.fetch(:tags, {}).keys.each do |t|
            @mnemonics[m].append(t)
            @ct_groups[t] = [] unless @ct_groups.key?(t)
            @ct_groups[t].append(m)
          end
        end
      end
    end
  end

  def self.options
    $options.nil? ? {} : $options
  end

  def self.debug
    self.options.fetch(:debug, false)
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
    @mnemonics.fetch(mnemonic, [])
  end

  def make_query_param
    qp = {}
    @config.fetch(:default_params, {}).each do |k,v|
      qp[k.to_sym] = v
    end
    qp
  end

  def make_options(argv)
    options = {query_params: {}, iterative_params: []}
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
        options[:query_params].append(make_query_param) if options[:query_params].empty?
        options[:query_params][:QUERY] = n.gsub(%r[[^A-Za-z0-9_\-]], "")
      end
      opts.on('--mnemonic=MNEMONIC', 'Set Query Param Mnemonic') do |n|
        options[:query_params].append(make_query_param) if options[:query_params].empty?
        options[:query_params][:MNEMONIC] = n.gsub(%r[[^a-z0-9_\-]], "")
        options[:query_params][:QUERY] = "collection"
      end
      opts.on('--tag=TAG', 'Set Collection TAG to process') do |n|
        @ct_groups.fetch(n.to_sym, []).each do |m|
          options[:iterative_params].append({MNEMONIC: m})
          options[:query_params][:QUERY] = "collection"
        end
      end
      opts.on('--id=ID', 'Set Query Param Id') do |n|
        options[:query_params].append(make_query_param) if options[:query_params].empty?
        options[:query_params][:ID] = n.to_i
        options[:query_params][:QUERY] = "id"
      end
      opts.on('--limit=LIMIT', 'Set Query Limit') do |n|
        options[:query_params][:LIMIT] = n.to_i
      end
    end.parse(ARGV)
    options[:iterative_params].append({}) if options[:iterative_params].empty?
    options    
  end

  def preliminary_tasks
    puts $options if ObjectHealth.debug
    @obj_health_db.clear_object_health(:build) if $options[:clear_build]
    @obj_health_db.clear_object_health(:analysis) if $options[:clear_analysis]
    @obj_health_db.clear_object_health(:tests) if $options[:clear_tests]
  end

  def process_objects
    @obj_health_db.get_object_list.each do |id|
      process_object(id)
    end
  end

  def process_tag(tag)
  end

  def export_object(ohobj)
    if ObjectHealth.debug
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
    puts id if ObjectHealth.debug
    ohobj = ObjectHealthObject.new(@build_config, id)
    ohobj.init_components
    if $options[:build_objects]
      puts "build #{id}" if ObjectHealth.debug
      @obj_health_db.build_object(ohobj)
      puts "save #{id}" if ObjectHealth.debug
      @obj_health_db.update_object_build(ohobj)
    else
      puts "get #{id}" if ObjectHealth.debug
      @obj_health_db.load_object_json(ohobj)
    end

    if $options[:analyze_objects] && ohobj.build.loaded?
      puts "  analyze #{id}" if ObjectHealth.debug
      @analysis_tasks.run_tasks(ohobj)
      @obj_health_db.update_object_analysis(ohobj)
    end

    if $options[:test_objects] && ohobj.build.loaded?
      puts "  test #{id}" if ObjectHealth.debug
      @obj_health_tests.run_tests(ohobj)
      @obj_health_db.update_object_tests(ohobj)
    end

    if ohobj.build.loaded? && ($options[:build_objects] || $options[:test_objects] || $options[:analyze_objects])
      puts "  export #{id}" if ObjectHealth.debug
      begin
        export_object(ohobj)
      rescue => e 
        puts "Export failed #{e}"
      end
    end

    if ObjectHealth.debug
      if @debug[:print_count] < @debug[:print_max]
        puts ohobj.build.pretty_json
        @debug[:print_count] += 1
      end
    end
  end

  def mode
    return :build if $options[:build_objects]
    return :analysis if $options[:analyze_objects]
    return :tests if $options[:test_objects]
    return :na
  end

  def inspect
    self.to_s
  end

  def self.match_first(ordered_list, list_set)
    ordered_list.each do |v|
      return v if list_set.include?(v)
    end
    return nil
  end

  def self.match_list(list, str)
    return false if list.nil?
    list.include?(str)
  end

  def self.match_map(map, str)
    return false if map.nil?
    self.match_list(map.keys, str)
  end

  def self.match_template_list(list, str, ohobj)
    return false if list.nil?

    tlist = []
    list.each do |v|
      tlist.append(Mustache.render(v, ohobj.nil? ? {} : ohobj.template_map))
    end
    self.match_list(tlist, str)
  end

  def self.match_pattern(list, str)
    return false if list.nil?

    list.each do |v|
      return true if str =~ Regexp.new(v)
    end
    false
  end

  def self.match_criteria(criteria:, key:, ohobj:, criteria_list: nil, criteria_keys: nil, criteria_templates: nil, criteria_patterns: nil)
    return false if criteria.nil?
    b = false
    b = b || self.match_list(criteria.fetch(criteria_list, []), key) if criteria_list
    b = b || self.match_map(criteria.fetch(criteria_keys, []), key) if criteria_keys
    b = b || self.match_pattern(criteria.fetch(criteria_patterns, []), key) if criteria_patterns
    b = b || self.match_template_list(criteria.fetch(criteria_templates, []), key, ohobj) if criteria_templates
    b
  end

  def self.make_status_key_map(criteria, key) 
    mapping = {}
    criteria.fetch(key, {}).each do |k,list|
      next if list.nil?
      list.keys.each do |v|
        mapping[v.to_sym] = k
      end
    end
    mapping
  end  
end

oh = ObjectHealth.new(ARGV)
oh.preliminary_tasks
oh.process_objects
