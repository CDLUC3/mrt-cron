class ObjectHealthObject
  def initialize(id)
    @osobj = {
      id: id,
      '@timestamp': Time.now.strftime("%Y-%m-%dT%H:%M:%S%z"),
      build: default_build(id),
      analysis: default_analysis,
      tests: default_tests
    }
  end


  def self.make_opensearch_date(modt)
    return '' if modt.nil?
    return '' if modt.to_s.empty?
    DateTime.parse("#{modt} -0700").to_s
  end

  def build_object_representation(r)
    loc = r.fetch('localids', '')
    loc = '' if loc.nil?
    @osobj[:build][:loaded] = true
    @osobj[:build][:identifiers] = {
      ark: r.fetch('ark', ''),
      localids: loc.split(',')
    }
    @osobj[:build][:containers] = {
      owner_ark: r.fetch('owner_ark', ''),
      coll_ark: r.fetch('coll_ark', ''),
      mnemonic: r.fetch('mnemonic', '')
    }
  
    @osobj[:build][:metadata] = {
      erc_who: r.fetch('erc_who', ''),
      erc_what: r.fetch('erc_what', ''),
      erc_when: r.fetch('erc_when', ''),
      erc_where: r.fetch('erc_where', '')
    }
    
    @osobj[:build][:modified] = ObjectHealthObject.make_opensearch_date(r.fetch('modified', ''))
    @osobj[:build][:embargo_end_date] = ObjectHealthObject.make_opensearch_date(r.fetch('embargo_end_date', ''))
  end

  def self.make_sidecar(sidecarText)
    sidecar = {}
    return sidecar if sidecarText.nil?
    return sidecar if sidecarText.empty?
    begin
      xml = Nokogiri::XML(sidecarText).remove_namespaces!
      xml.xpath("//*[not(descendant::*)]").each do |n|
        sidecar[n.name] = sidecar.fetch(n.name, []).append(n.text)
      end
    rescue => exception
      puts exception
    end
    sidecar
  end

  def set_sidecar(text)
    @osobj[:build][:sidecar] = get_build.fetch(:sidecar, [])
    @osobj[:build][:sidecar].append(make_sidecar(text))
  end

  def process_object_file(r)
    @osobj[:build][:file_counts] = get_build.fetch(:file_counts, {})
    init_object_mimes
    source = r.fetch('source', 'na').to_sym
    @osobj[:build][source] = [] unless get_build.key?(source)
    @osobj[:build][:file_counts][source] = get_build[:file_counts].fetch(source, 0) + 1
    mime = r.fetch('mime_type', '')
    if get_build[:file_counts][source] <= 1000
      @osobj[:build][source].push({
        version: r.fetch('number', 0),
        pathname: r.fetch('pathname', ''),
        billable_size: r.fetch('billable_size', 0),
        mime_type: mime,
        digest_type: r.fetch('digest_type', ''),
        digest_value: r.fetch('digest_value', ''),
        created: r.fetch('created', '')
      })
    end
    if source == :producer and !mime.empty?
      count_mime(mime)
    end
  end

  def to_json
    @osobj.to_json
  end

  def get_build
    @osobj[:build]
  end

  def get_osobj
    @osobj
  end

  def get_object_mimes
    get_build.fetch(:mimes, {})
  end

  def init_object_mimes
    @osobj[:build][:mimes] = get_object_mimes
  end

  def count_mime(mime)
    get_object_mimes[mime.to_sym] = get_object_mimes.fetch(mime.to_sym, 0) + 1
  end

  def default_analysis
    {}
  end

  def init_analysis
    set_analysis(default_analysis)
  end

  def get_analysis
    @osobj[:analysis]
  end

  def set_analysis(analysis)
    @osobj[:analysis] = default_analysis
    analysis.each do |k,v|
      @osobj[:analysis][k.to_sym] = v
    end
  end

  def set_analysis_json(json)
    set_analysis(JSON.parse(json, symbolize_names: true)) unless json.nil?
  end


  def get_analysis_mimes
    get_analysis.fetch(:mimes, {})
  end

  def set_analysis_mimes(objmap)
    @osobj[:analysis][:mimes] = objmap
  end

  def default_tests
    tres = {failures: [], summary: '', test_run_log: []}
    ObjectHealth.status_values.each do |stat|
      tres[stat] = 0
    end
    tres
  end

  def init_tests
    set_tests(@osobj.fetch(:tests, default_tests))
  end

  def set_tests(tests)
    @osobj[:tests] = tests
  end

  def set_tests_json(json)
    set_tests(JSON.parse(json, symbolize_names: true)) unless json.nil?
  end


  def get_tests
    @osobj[:tests]
  end
       
  def record_test(name, status)
    @osobj[:tests][name.to_sym] = status
    @osobj[:tests][status] += 1
    @osobj[:tests][:failures] = @tests.fetch(:failures, []).append(name) if status == :FAIL
  end

  def id
    @osobj.fetch(:id, 0)
  end

  def default_build(id)
    {
      id: id, 
      loaded: false
    }
  end

  def set_build(build)
    @osobj[:build] = build
  end

  def set_build_json(json)
    set_build(JSON.parse(json, symbolize_names: true)) unless json.nil?
  end

  def pretty_json
    JSON.pretty_generate(get_build)
  end

  def loaded?
    get_build.fetch(:loaded, false)
  end
end