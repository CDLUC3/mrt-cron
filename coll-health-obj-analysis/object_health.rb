require 'json'
require 'json-schema'

require 'yaml'
require 'uc3-ssm'
require 'optparse'
require 'opensearch'
require 'time'
require_relative 'object_health_util'
require_relative 'object_health_db'
require_relative 'object_health_cli'
require_relative 'object_health_tests'
require_relative 'object_health_opensearch'
require_relative 'object_health_match'
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
  def initialize(argv = [], cfdb: 'config/database.ssm.yml', cfos: 'config/opensearch.ssm.yml', cfmc: ObjectHealthUtil.merritt_classifications)
    @schema_yaml = ObjectHealthUtil.get_and_validate_schema_file(ObjectHealthUtil.yaml_schema)
    @schema_obj = ObjectHealthUtil.get_and_validate_schema_file(ObjectHealthUtil.obj_schema)
    config_db = ObjectHealthUtil.get_ssm_config(cfdb)
    config_opensearch = ObjectHealthUtil.get_ssm_config(cfos)
    # for rspec purposes, allow the cfmc to be overridden before construction
    config = cfmc.is_a?(Hash) ? cfmc : ObjectHealthUtil.get_config(cfmc)
    ObjectHealthUtil.validate(@schema_yaml, config, ObjectHealthUtil.yaml_schema, verbose: verbose)
    config_rules = config.fetch(:classifications, {})
    config_cli = config.fetch(:runtime, {})

    # map mnemonics to groups
    @mnemonics = {}
    # map collection taxonomy groups to mnemonics
    @ct_groups = {}
    load_collection_taxonomy(config_rules)
    @build_config = config_rules.fetch(:build_config, {})

    @obj_health_cli = ObjectHealthCli.new(config_cli, @ct_groups, argv)
    @obj_health_db = ObjectHealthDb.new(self, config_db, mode)
    @analysis_tasks = AnalysisTasks.new(self, config_rules)
    @obj_health_tests = ObjectHealthTests.new(self, config_rules)
    @opensrch = ObjectHealthOpenSearch.new(self, config_opensearch)

    now = Time.now.strftime("%Y-%m-%d %H:%M:%S")
  end

  def validation
    @obj_health_cli.validation
  end

  def debug
    @obj_health_cli.debug
  end

  def verbose
    return false if ENV.key?("OBJHEALTH_SILENT")
    return true if @obj_health_cli.nil?
    @obj_health_cli.verbose
  end

  def options
    @obj_health_cli.options
  end

  def load_collection_taxonomy(config_rules)
    config_rules.fetch(:collection_taxonomy, []).each do |ctdef|
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

  def collection_taxonomy(mnemonic)
    @mnemonics.fetch(mnemonic, [])
  end

  def preliminary_tasks
    puts @obj_health_cli.options if debug
    status = @obj_health_db.object_health_status
    if options[:clear_build]
      awaiting = status.fetch(:awaiting_rebuild, 0)
      if awaiting == 0 || options[:force_rebuild]
        puts "\n *** This will trigger a rebuild of #{status.fetch(:built, 0)} records.  Type 'yes' to continue or 'exit' to cancel.\n"
        while input = STDIN.gets.chomp 
          break if input == "yes"
          exit if input == "exit" 
        end
        @obj_health_db.clear_object_health(:build)
      else
        puts "\n *** Cannot clear build because #{awaiting} objects are awaiting rebuild.  Add --force-rebuild to continue anyway.\n"
        exit
      end
    end
    @obj_health_db.clear_object_health(:analysis) if options[:clear_analysis]
    @obj_health_db.clear_object_health(:tests) if options[:clear_tests]
  end

  def get_object_list
    @obj_health_db.get_object_list
  end

  def process_objects
    get_object_list.each do |id|
      process_object(id)
    end
  end

  def process_tag(tag)
  end

  def export_object(ohobj)
    if @obj_health_cli.export_object
      File.open("debug/objects_details.#{ohobj.id}.json", 'w') do |f|
        f.write(JSON.pretty_generate(ohobj.get_osobj))
      end
    end
    @opensrch.export(ohobj)
  end

  def process_object(id)
    puts id if debug
    ohobj = ObjectHealthObject.new(@build_config, id)
    ohobj.init_components
    if options[:build_objects]
      puts "build #{id}" if debug
      @obj_health_db.build_object(ohobj)
      puts "save #{id}" if debug
      @obj_health_db.update_object_build(ohobj)
    else
      puts "get #{id}" if debug
      @obj_health_db.load_object_json(ohobj)
    end

    if options[:analyze_objects] && ohobj.build.loaded?
      puts "  analyze #{id}" if debug
      @analysis_tasks.run_tasks(ohobj)
      @obj_health_db.update_object_analysis(ohobj)
    end

    if options[:test_objects] && ohobj.build.loaded?
      puts "  test #{id}" if debug
      @obj_health_tests.run_tests(ohobj)
      @obj_health_db.update_object_tests(ohobj)
    end

    if ohobj.build.loaded? && (options[:build_objects] || options[:test_objects] || options[:analyze_objects])
      begin
        puts "  export #{id}" if debug
        export_object(ohobj)
        if validation
          puts "  validate #{ohobj.id}" if debug
          ObjectHealthUtil.validate(@schema_obj, ohobj.get_osobj, ohobj.id, verbose: verbose)
        end
      rescue => e 
        puts "Export failed #{e}"
      end
    end
 
    puts ohobj.build.pretty_json if @obj_health_cli.check_print
  end

  def mode
    return :build if options[:build_objects]
    return :analysis if options[:analyze_objects]
    return :tests if options[:test_objects]
    return :na
  end

  def inspect
    self.to_s
  end

end
