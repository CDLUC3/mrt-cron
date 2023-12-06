require 'cgi'

class OSFormatter
  def self.create(options, osfdef)
    unless osfdef.nil?
      osfclass = osfdef.fetch(:class, '')
      unless osfclass.empty?
        Object.const_get(osfclass).new(options, osfdef)
      end
    end
  end
            
  def initialize(options, osfdef)
    @options = options
    @osfdef = osfdef
    @results = []
    @doc = {}
  end

  def results
    @results
  end

  def init_test
  end

  def set_doc(doc)
    @doc = doc
    init_test
  end

  def make_result(doc)
    set_doc(doc)
    res = format
    @results.append(res) unless res.nil?
  end

  def format
    {
      ark: @doc.fetch("build", {}).fetch("identifiers", {}).fetch("ark", ""), 
      id: @doc.fetch("id", ""),
      producer_count: @doc.fetch("build", {}).fetch("file_counts", {}).fetch("producer", 0),
      files: files
    }
  end

  def print(rec, index)
    puts "#{index}. #{rec[:ark]} (#{rec[:producer_count]})"
    rec.fetch(:files, []).each do |f|
      puts "\t#{f.fetch(:path, '')}"
    end
  end

  def query
    defq = {match: {not_applicable: 'na'}}
    @osfdef.fetch(:query, defq)
  end

  def url
    @doc.fetch("analysis", {}).fetch("containers", {}).fetch("url", "")
  end

  def file_url
    url.gsub(%r[\/m\/], "/api/presign-file/")
  end

  def has_file_test
    false
  end

  def file_test(f)
    false
  end

  def files
    rfiles = []
    return riles unless has_file_test
    @doc.fetch("build", {}).fetch("producer", []).each_with_index do |f, i|
      next if f.fetch("ignore_file", false)
      next unless file_test(f)
      p = CGI::escape(f.fetch("pathname", ""))
      v = f.fetch("version", "0")
      rfiles.append({
        path: "#{v}/#{p}",
        url: "#{file_url}/#{v}/#{p}"
      })
      break if rfiles.length >= @options.fetch(:max_file_per_object, 5)
    end
    rfiles
  end
end