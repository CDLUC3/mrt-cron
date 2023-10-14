class ObjectHealthObject
  def initialize(id)
    @obj = {
      id: id, 
      loaded: false, 
      processing: {}
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
    @obj[:loaded] = true
    @obj[:identifiers] = {
      ark: r.fetch('ark', ''),
      localids: loc.split(',')
    }
    @obj[:containers] = {
      owner_ark: r.fetch('owner_ark', ''),
      coll_ark: r.fetch('coll_ark', ''),
      mnemonic: r.fetch('mnemonic', '')
    }
  
    @obj[:metadata] = {
      erc_who: r.fetch('erc_who', ''),
      erc_what: r.fetch('erc_what', ''),
      erc_when: r.fetch('erc_when', ''),
      erc_where: r.fetch('erc_where', '')
    }
    @obj[:@timestamp] = ObjectHealthObject.make_opensearch_date(r.fetch('modified', ''))
    @obj[:modified] = ObjectHealthObject.make_opensearch_date(r.fetch('modified', ''))
    @obj[:embargo_end_date] = ObjectHealthObject.make_opensearch_date(r.fetch('embargo_end_date', ''))
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
    @obj[:sidecar] = @obj.fetch(:sidecar, [])
    @obj[:sidecar].append(make_sidecar(text))
  end

  def process_object_file(r)
    @obj[:file_counts] = @obj.fetch(:file_counts, {})
    @obj[:mimes] = @obj.fetch(:mimes, {})
    source = r.fetch('source', 'na').to_sym
    @obj[source] = [] unless @obj.key?(source)
    @obj[:file_counts][source] = @obj[:file_counts].fetch(source, 0) + 1
    mime = r.fetch('mime_type', '')
    if @obj[:file_counts][source] <= 1000
      @obj[source].push({
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
      @obj[:mimes][mime] = @obj[:mimes].fetch(mime, 0) + 1
    end
  end

  def to_json
    @obj.to_json
  end

  def get_obj
    @obj
  end
    
  def init_analysis
    @obj[:analysis] = @obj.fetch(:analysis, {})
  end

  def get_analysis
    get_obj.fetch(:analysis, {})
  end

  def set_analysis(analysis)
    @obj[:analysis] = analysis
  end

  def init_tests
    tres = {failures: [], summary: '', test_run_log: []}
    ObjectHealth.status_values.each do |stat|
      tres[stat] = 0
    end
    @obj[:tests] = obj.fetch(:tests, tres)
    @obj[:tests][:test_run_log] = obj[:tests].fetch(:test_run_log, []).append(Time.now.to_s)
  end
       
  def record_test(name, status)
    @obj[:tests][name.to_sym] = status
    @obj[:tests][status] += 1
    @obj[:tests][:failures] = @obj[:tests].fetch(:failures, []).append(name) if status == :FAIL
  end

  def id
    @obj.fetch(:id, 0)
  end

  def set_json(json)
    @obj = JSON.parse(json, symbolize_names: true)
  end

  def pretty_json
    JSON.pretty_generate(get_obj)
  end
end