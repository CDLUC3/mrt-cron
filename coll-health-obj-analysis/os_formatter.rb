# frozen_string_literal: true

require 'erb'

class OSFormatter
  def self.create(options, osfdef)
    unless osfdef.nil?
      osfclass = osfdef.fetch(:class, '')
      Object.const_get(osfclass).new(options, osfdef) unless osfclass.empty?
    end
  end

  def initialize(options, osfdef)
    @options = options
    @osfdef = osfdef
    @results = []
    @doc = {}
    @filter = {}
    set_filter
  end

  def set_filter
    @filter = { bool: { must: [] } } if (@options[:ark] || @options[:mnemonic]) && @filter.empty?
    if @options[:ark]
      @filter[:bool][:must].append({
                                     match_phrase: {
                                       "build.identifiers.ark": @options[:ark]
                                     }
                                   })
    end
    if @options[:mnemonic]
      @filter[:bool][:must].append({
                                     match: {
                                       "build.containers.mnemonic": @options[:mnemonic]
                                     }
                                   })
    end
  end

  attr_reader :results

  def init_test; end

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
      ark: @doc.fetch('build', {}).fetch('identifiers', {}).fetch('ark', ''),
      id: @doc.fetch('id', ''),
      producer_count: @doc.fetch('build', {}).fetch('file_counts', {}).fetch('producer', 0),
      files: files
    }
  end

  def print(outputter, rec, index)
    outputter.output(rec, index)
  end

  def query
    defq = { match: { not_applicable: 'na' } }
    q = @osfdef.fetch(:query, defq)
    unless @filter.empty?
      q = {
        bool: {
          filter: @filter,
          must: [
            q
          ]
        }
      }
    end
    q
  end

  def url
    @doc.fetch('analysis', {}).fetch('containers', {}).fetch('url', '')
  end

  def file_url
    url.gsub(%r{/m/}, '/api/presign-file/')
  end

  def has_file_test
    false
  end

  def file_test(f)
    file_filters(f)
  end

  def file_filters(f)
    b = true
    b &= f['pathname'] =~ @options[:file_path_regex] if @options[:file_path_regex]
    b &= f['mime_type'] =~ @options[:file_mime_regex] if @options[:file_mime_regex]
    b
  end

  def files
    rfiles = []
    return rfiles unless has_file_test

    @doc.fetch('build', {}).fetch('producer', []).each_with_index do |f, _i|
      next if f.fetch('ignore_file', false)
      next unless file_test(f)

      p = f.fetch('pathname', '')
      pesc = ERB::Util.url_encode(p)
      v = f.fetch('version', '0')
      rfiles.append({
                      path: "#{v}/#{p}",
                      url: "#{file_url}/#{v}/#{pesc}",
                      mime_type: f.fetch('mime_type', ''),
                      ext: f.fetch('ext', '')
                    })
      break if rfiles.length >= @options.fetch(:max_file_per_object, 5)
    end
    rfiles
  end
end

class OSFilesFormatter < OSFormatter
  def has_file_test
    true
  end
end
