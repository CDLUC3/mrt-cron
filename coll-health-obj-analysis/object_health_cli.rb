# frozen_string_literal: true

require 'json'
require 'optparse'

# Merritt Object Health command line argument processor
class ObjectHealthCli
  def initialize(config, ct_groups, argv)
    @config = config
    @ct_groups = ct_groups
    @options = make_options(argv)
    @debug = {
      export_count: 0,
      export_max: @config.fetch(:debug, {}).fetch(:export_max, 5),
      print_count: 0,
      print_max: @config.fetch(:debug, {}).fetch(:print_max, 1)
    }
    @options[:query_params][:SKIPS] = ''
    return unless @ct_groups.key?(:tag_skip)

    @options[:query_params][:SKIPS] = @ct_groups[:tag_skip].map do |s|
      "'#{s}'"
    end.join(',')
  end

  def debug
    @options.fetch(:debug, false)
  end

  def verbose
    @options.fetch(:verbose, true)
  end

  def validation
    return @options[:validation] if @options.key?(:validation)

    @config.fetch(:validation, false)
  end

  def make_options(argv)
    options = {
      query_params: @config.fetch(:default_params, {}),
      iterative_params: []
    }
    # not parse(argv) at the end of the loop
    OptionParser.new do |opts|
      opts.banner = 'Usage: ruby object_health.rb'
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
      opts.on('--force-rebuild', 'Force restart of rebuild') do
        options[:force_rebuild] = true
      end
      opts.on('--clear-analysis', 'Clear Analysis Records') do
        options[:clear_analysis] = true
      end
      opts.on('--clear-tests', 'Clear Tests Records') do
        options[:clear_tests] = true
      end
      opts.on('--validation', 'Validate Objects before export') do
        options[:validation] = true
      end
      opts.on('--no-validation', 'No Object Validation') do
        options[:validation] = false
      end
      opts.on('--silent', 'Silent mode, suppress verbose status') do
        options[:verbose] = false
      end
      # The following values may be edited into yaml queries... perform some sanitization on the values
      opts.on('--query=QUERY', 'Object Selection Query to Use') do |n|
        options[:query_params][:QUERY] = n.gsub(/[^A-Za-z0-9_-]/, '')
      end
      opts.on('--mnemonic=MNEMONIC', 'Set Query Param Mnemonic') do |n|
        options[:query_params][:MNEMONIC] = n.gsub(/[^a-z0-9_-]/, '')
        options[:query_params][:QUERY] = 'collection'
      end
      opts.on('--tag=TAG', 'Set Collection TAG to process') do |n|
        @ct_groups.fetch(n.to_sym, []).each do |m|
          options[:iterative_params].append({ MNEMONIC: m })
          options[:query_params][:QUERY] = 'collection'
        end
      end
      opts.on('--id=ID', 'Set Query Param Id') do |n|
        options[:query_params][:ID] = n.to_i
        options[:query_params][:QUERY] = 'id'
      end
      opts.on('--limit=LIMIT', 'Set Query Limit') do |n|
        options[:query_params][:LIMIT] = n.to_i
      end
      opts.on('--loop=COUNT', 'Set Loop Limit') do |n|
        options[:loop_limit] = n.to_i
      end
      opts.on('--sleep=SECS', 'Set sleep time between loops') do |n|
        options[:loop_sleep] = n.to_i
      end
    end.parse(argv)
    options[:iterative_params].append({}) if options[:iterative_params].empty?

    if options[:iterative_params].length > 1 &&
       (options[:force_rebuild] || options[:clear_analysis] || options[:clear_tests])
      puts '--clear- options are not allowed when a tag set is in use'
      exit(0)
    end

    options
  end

  attr_reader :options

  def check_print
    if debug && (@debug[:print_count] < @debug[:print_max])
      @debug[:print_count] += 1
      return true
    end
    false
  end

  def export_object
    if debug && (@debug[:export_count] < @debug[:export_max])
      @debug[:export_count] += 1
      return true
    end
    false
  end
end
