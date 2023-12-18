# frozen_string_literal: true

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
require_relative 'oh_stats'
# Merritt Object Health driver
# The business rules for this class are in config/merritt_classifications.yml
# Configurable TASK and TEST classes are referenced by classname in the yaml file.
# - the BUILD step extracts data from the Merritt inventory database and writes that information
#   to an easily traversible JSON structure.
# - the ANALYSIS step applies a configurable set of Tasks to build JSON creating analysis JSON
#   that will be used by the next step.
# - the TEST step applies a configurable set of Tests to the build and analysis JSON recording
#   results into a Test JSON structure.
# All tests are configured to return one status from the following values:
# - SKIP, PASS, INFO, WARN, FAIL
# The JSON content is written to OpenSearch for end user faceting and querying.
class ObjectHealth
  def initialize(
    argv = [],
    cfdb: 'config/database.ssm.yml',
    cfos: 'config/opensearch.ssm.yml',
    cfmc: ObjectHealthUtil.merritt_classifications
  )
    @schema_yaml = ObjectHealthUtil.read_and_validate_schema_file(ObjectHealthUtil.yaml_schema)
    @schema_obj = ObjectHealthUtil.read_and_validate_schema_file(ObjectHealthUtil.obj_schema)
    config_db = ObjectHealthUtil.ssm_config(cfdb)
    config_opensearch = ObjectHealthUtil.ssm_config(cfos)
    # for rspec purposes, allow the cfmc to be overridden before construction
    config = cfmc.is_a?(Hash) ? cfmc : ObjectHealthUtil.config_from_yaml(cfmc)
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
    @opensrch = ObjectHealthOpenSearch.new(config_opensearch)

    Time.now.strftime('%Y-%m-%d %H:%M:%S')
  end

  def validation
    @obj_health_cli.validation
  end

  def debug
    @obj_health_cli.debug
  end

  def verbose
    return false if ENV.key?('OBJHEALTH_SILENT')
    return true if @obj_health_cli.nil?

    @obj_health_cli.verbose
  end

  def options
    @obj_health_cli.options
  end

  def loop_limit
    options.fetch(:loop_limit, 1)
  end

  def loop_sleep
    options.fetch(:loop_sleep, 1)
  end

  def load_collection_taxonomy(config_rules)
    config_rules.fetch(:collection_taxonomy, []).each do |ctdef|
      next if ctdef.nil?

      ctdef.fetch(:groups, {}).each_key do |g|
        ctdef.fetch(:mnemonics, {}).each do |m, mdef|
          @mnemonics[m] = [] unless @mnemonics.key?(m)
          @mnemonics[m].append(g) unless @mnemonics[m].include?(g)
          @ct_groups[g] = [] unless @ct_groups.key?(g)
          @ct_groups[g].append(m) unless @ct_groups[g].include?(m)
          next if mdef.nil?

          mdef.fetch(:tags, {}).each_key do |t|
            @mnemonics[m].append(t) unless @mnemonics[m].include?(t)
            @ct_groups[t] = [] unless @ct_groups.key?(t)
            @ct_groups[t].append(m) unless @ct_groups[t].include?(m)
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
      if awaiting.zero? || options[:force_rebuild]
        if verbose
          puts <<~HERE
            *** This will trigger a rebuild of #{status.fetch(:built, 0)} records.
                Type 'yes' to continue or 'exit' to cancel.

          HERE
          while (input = $stdin.gets.chomp)
            break if input == 'yes'

            exit if input == 'exit'
          end
        end
        @obj_health_db.clear_object_health(:build)
      else
        if verbose
          puts <<~HERE
            *** Cannot clear build because #{awaiting} objects are awaiting rebuild.
                Add --force-rebuild to continue anyway.

          HERE
        end
        exit
      end
    end
    @obj_health_db.clear_object_health(:analysis) if options[:clear_analysis]
    @obj_health_db.clear_object_health(:tests) if options[:clear_tests]
  end

  def hash_object_list
    @obj_health_db.hash_object_list
  end

  def sql_clear_query
    @obj_health_db.clear_query
  end

  def sql_queries
    @obj_health_db.queries
  end

  def process_objects
    ohstat = ObjectHealthStats.new(loop_sleep)
    while ohstat.loop_num < loop_limit
      ohstat.log_loop if verbose
      ohstat.loop_start
      hash_object_list.each do |id|
        process_object(id)
        ohstat.increment
      end
    end
    ohstat.log_loop(last: true) if verbose
    ohstat.log_loops if verbose

    @obj_health_db.object_health_status
  end

  def process_tag(tag); end

  def export_object(ohobj)
    if @obj_health_cli.export_object
      File.write("debug/objects_details.#{ohobj.id}.json", JSON.pretty_generate(ohobj.opensearch_obj))
    end
    @opensrch.export(ohobj)
  end

  def process_object(object_id)
    puts object_id if debug
    ohobj = ObjectHealthObject.new(@build_config, object_id)
    ohobj.init_components
    if options[:build_objects]
      puts "build #{object_id}" if debug
      @obj_health_db.build_object(ohobj)
      puts "save #{object_id}" if debug
      @obj_health_db.update_object_build(ohobj)
    else
      puts "get #{object_id}" if debug
      @obj_health_db.load_object_json(ohobj)
    end

    if options[:analyze_objects] && ohobj.build.loaded?
      puts "  analyze #{object_id}" if debug
      @analysis_tasks.run_tasks(ohobj)
      @obj_health_db.update_object_analysis(ohobj)
    end

    if options[:test_objects] && ohobj.build.loaded?
      puts "  test #{object_id}" if debug
      @obj_health_tests.run_tests(ohobj)
      @obj_health_db.update_object_tests(ohobj)
    end

    if ohobj.build.loaded? && (options[:build_objects] || options[:test_objects] || options[:analyze_objects])
      begin
        puts "  export #{object_id}" if debug
        ohobj.opensearch_obj[:exported] = DateTime.now.to_s

        if validation
          begin
            puts "  validate #{ohobj.id}" if debug
            ohobj.opensearch_obj[:validated] =
              ObjectHealthUtil.validate(@schema_obj, ohobj.opensearch_obj, ohobj.id, verbose: verbose)
          rescue MySchemaException => e
            ohobj.opensearch_obj[:validated] = false
            ohobj.opensearch_obj[:validation_error] = e.errors
          end
        end
        export_object(ohobj)
        @obj_health_db.update_object_exported(ohobj)
      rescue StandardError => e
        puts "Export failed #{e}"
      end
    end

    puts ohobj.build.pretty_json if @obj_health_cli.check_print
  end

  def mode
    return :build if options[:build_objects]
    return :analysis if options[:analyze_objects]
    return :tests if options[:test_objects]

    :na
  end

  def inspect
    to_s
  end

  def opensearch
    @opensrch
  end
end

if $PROGRAM_NAME == __FILE__
  objh = ObjectHealth.new(ARGV)
  objh.preliminary_tasks
  objh.process_objects
end
