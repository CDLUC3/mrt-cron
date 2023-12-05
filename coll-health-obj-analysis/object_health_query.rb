require_relative 'object_health'
require 'cgi'

class Formatter
  def initialize
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
    if has_file_test
      files
    else
      {
        ark: @doc.fetch("build", {}).fetch("identifiers", {}).fetch("ark", ""), 
        id: @doc.fetch("id", "")
      }
    end
  end

  def print_format(rec)
    rec.fetch(:ark, "")
  end

  def print(rec)
    s = print_format(rec)
    puts s unless s.empty?
  end

  def query
    {exists: {"field": "id"}}
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
    @doc.fetch("build", {}).fetch("producer", []).each do |f|
      next if f.fetch("ignore_file", false)
      next unless file_test(f)
      p = CGI::escape(f.fetch("pathname", ""))
      v = f.fetch("version", "0")
      @results.append({path: "#{file_url}/#{v}/#{p}"})
    end
    nil
  end
end

class UnsustainableMimeFormatter < Formatter
  def initialize
    super
    @mimes_to_report = []
  end

  def init_test
    @mimes_to_report = []
    @doc.fetch("analysis", {}).fetch("mimes_by_status", {}).each do |k, v|
      next if k == "PASS"
      v.each do |m|
        @mimes_to_report.append(m)
      end
    end
  end

  def has_file_test
    true
  end

  def file_test(f)
    @mimes_to_report.include?(f.fetch("mime_type", ""))
  end

  def query
    {match: {"tests.summary": "unsustainable-mime-type"}}
  end

  def print_format(rec)
    rec.fetch(:path, "")
  end
end

class ObjectHealthQuery
  def initialize
    @oh = ObjectHealth.new([])
    @opensearch = @oh.opensearch
  end              

  def run_query
    fmt = UnsustainableMimeFormatter.new
    @opensearch.query(fmt, 1000)
    fmt.results.each do |rec|
      fmt.print(rec)
    end
  end
end

ohq = ObjectHealthQuery.new
ohq.run_query

