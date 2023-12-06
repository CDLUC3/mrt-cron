require 'yaml'
require 'uc3-ssm'
require 'optparse'
require_relative 'object_health_opensearch'
require_relative 'object_health_util'

Dir[File.dirname(__FILE__) + '/os_formatter*.rb'].each {|file| require file }

class ObjectHealthQuery
  def initialize(argv = [], cfos: 'config/opensearch.ssm.yml', cfq: 'config/os_queries.yml')
    config_opensearch = ObjectHealthUtil.get_ssm_config(cfos)
    @opensearch = ObjectHealthOpenSearch.new(config_opensearch)
    @query_config = ObjectHealthUtil.get_config(cfq)
    @options = make_options(argv)
  end     
  
  def get_formatter(q)
    osfconfig = @query_config.fetch(:queries, {}).fetch(q, nil)
    osf = OSFormatter.create(@options, osfconfig)
  end

  def queries
    @query_config.fetch(:queries, {}).keys
  end

  def run_query
    fmt = get_formatter(@options.fetch(:fmt, 'default').to_sym)
    return if fmt.nil?
    @opensearch.query(
      fmt, 
      @options.fetch(:start, 0),
      @options.fetch(:limit, 10),
      @options.fetch(:page_size, 10)
    )
    fmt.results.each_with_index do |rec, i|
      fmt.print(rec, i+1)
    end
  end

  def make_options(argv)
    options = @query_config.fetch(:options, {})
    # not parse(argv) at the end of the loop
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby object_health_query.rb"
      opts.on('-h', '--help', 'Show help and exit') do
        puts opts
        exit(0)
      end
      opts.on('--fmt=FORMATTER', "Open Search Query/Formatter: #{queries}") do |n|
        options[:fmt] = n
      end
      opts.on('--start=0', "Open Search results start index") do |n|
        options[:start] = n.to_i
      end
      opts.on('--limit=50', "Open Search results limit index") do |n|
        options[:limit] = n.to_i
      end
      opts.on('--page_size=10', "Page Size for processing Open Search results") do |n|
        options[:page_size] = n.to_i
      end
      opts.on('--max_file_per_object=1000', "Maximum number of files to report per object") do |n|
        options[:max_file_per_object] = n.to_i
      end
    end.parse(argv)
    options    
  end

  def options
    @options
  end
end

ohq = ObjectHealthQuery.new(ARGV)
ohq.run_query

