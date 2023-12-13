require 'yaml'
require 'uc3-ssm'
require 'optparse'
require_relative 'object_health_opensearch'
require_relative 'object_health_util'
require_relative 'outputters'
require_relative 'fits_outputter'

Dir[File.dirname(__FILE__) + '/os_formatter*.rb'].each {|file| require file }

class ObjectHealthQuery
  def initialize(argv = [], cfos: 'config/opensearch.ssm.yml', cfq: 'config/os_queries.ssm.yml')
    config_opensearch = ObjectHealthUtil.get_ssm_config(cfos)
    @opensearch = ObjectHealthOpenSearch.new(config_opensearch)
    @query_config = ObjectHealthUtil.get_ssm_config(cfq)
    @options = make_options(argv)
    @outputter = get_outputter(@options[:output])
  end     
  
  def merritt_config
    @query_config.fetch(:merritt, {})
  end

  def outputters
    @query_config.fetch(:outputs, {})
  end

  def get_outputter(q)
    outp = ConsoleOutput.new(merritt_config)
    outclass = outputters.fetch(q, {}).fetch(:class, "")
    outp = Object.const_get(outclass).new(merritt_config) unless outclass.empty?
    outp
  end

  def get_formatter(q)
    osfconfig = @query_config.fetch(:queries, {}).fetch(q, nil)
    osf = OSFormatter.create(@options, osfconfig)
  end

  def queries
    @query_config.fetch(:queries, {}).keys
  end

  def run_query
    fmt = get_formatter(@options.fetch(:fmt, :default))
    return if fmt.nil?
    @opensearch.query(
      fmt, 
      @options.fetch(:start, 0),
      @options.fetch(:limit, 10),
      @options.fetch(:page_size, 10)
    )
    fmt.results.each_with_index do |rec, i|
      fmt.print(@outputter, rec, i+1)
    end
  end

  def make_options(argv)

    options = @query_config.fetch(:options, {})
    [:fmt, :output].each do |k|
      options[k] = options[k].to_sym if options.key?(k)
    end

    # not parse(argv) at the end of the loop
    OptionParser.new do |opts|
      opts.banner = "Usage: ruby object_health_query.rb"
      opts.on('-h', '--help', 'Show help and exit') do
        puts opts
        exit(0)
      end
      opts.on('--fmt=FORMATTER', "Open Search Query/Formatter: #{queries}") do |n|
        options[:fmt] = n.to_sym
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
      opts.on('--output=OUTPUTTER', "Outputter #{outputters.keys}") do |n|
        options[:output] = n.to_sym
      end
      opts.on('--ark=ARK', 'Scope query to specified ARK') do |n|
        options[:ark] = n
      end
      opts.on('--mnemonic=MNEMONIC', 'Scope query to specified mnemonic') do |n|
        options[:mnemonic] = n
      end
      opts.on('--file_path_regex=REGEX', 'Regex to filter files to return by pathname') do |n|
        options[:file_path_regex] = Regexp.new(n)
      end
      opts.on('--file_mime_regex=REGEX', 'Regex to filter files to return by mime_type') do |n|
        options[:file_mime_regex] = Regexp.new(n)
      end
    end.parse(argv)

    # the default extractor does not pull file details... change the formatter if needed
    options[:fmt] = :files if options[:fmt] == :default && (options[:output] == :files || options[:output] == :fits)
    options    
  end

  def options
    @options
  end
end

ohq = ObjectHealthQuery.new(ARGV)
ohq.run_query

