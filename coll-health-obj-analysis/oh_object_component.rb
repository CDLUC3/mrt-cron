require 'json'

class ObjectHealthObjectComponent
  def initialize(ohobj, key)
    @ohobj = ohobj
    @compkey = key
    @ohobj.get_osobj[@compkey] = default_object
  end

  def default_object
    {}
  end

  def to_json
    get_object.to_json
  end

  def get_object
    @ohobj.get_osobj[@compkey]
  end

  def set_object(obj)
    @ohobj.get_osobj[@compkey] = obj
  end

  def init_object
    set_object(default_object)
  end

  def set_object_from_json(json)
    set_object(JSON.parse(json, symbolize_names: true)) unless json.nil?
  end

  def pretty_json
    JSON.pretty_generate(get_object)
  end    

  def set_key(key, val)
    @ohobj.set_key(@compkey, key, val)
  end

  def append_key(key, val)
    @ohobj.append_key(@compkey, key, val)
  end
    
  def increment_key(key)
    @ohobj.increment_key(@compkey, key)
  end

  def increment_subkey(key, subkey)
    @ohobj.increment_subkey(@compkey, key, subkey)
  end
end

class ObjectHealthObjectBuild < ObjectHealthObjectComponent
  def initialize(ohobj, key)
    super(ohobj, key)
  end

  def default_object
    {
      id: @ohobj.id, 
      loaded: false
    }
  end

  def loaded?
    get_object.fetch(:loaded, false)
  end

  def build_object_representation(r)
    loc = r.fetch('localids', '')
    loc = '' if loc.nil?
    set_key(:loaded, true)
    set_key(:identifiers, {
      ark: r.fetch('ark', ''),
      localids: loc.split(',')
    })
    set_key(:containers, {
      owner_ark: r.fetch('owner_ark', ''),
      coll_ark: r.fetch('coll_ark', ''),
      mnemonic: r.fetch('mnemonic', '')
    })
    set_key(:metadata, {
      erc_who: r.fetch('erc_who', ''),
      erc_what: r.fetch('erc_what', ''),
      erc_when: r.fetch('erc_when', ''),
      erc_where: r.fetch('erc_where', '')
    })
    set_key(:modified, ObjectHealthObject.make_opensearch_date(r.fetch('modified', '')))
    set_key(:embargo_end_date, ObjectHealthObject.make_opensearch_date(r.fetch('embargo_end_date', '')))
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
    append_key(:sidecar, make_sidecar(text))
  end
    
  def process_object_file(r)
    set_key(:file_counts, get_object.fetch(:file_counts, {}))
    init_object_mimes
    source = r.fetch('source', 'na').to_sym
    increment_subkey(:file_counts, source)
    mime = r.fetch('mime_type', '')
    if get_object[:file_counts][source] <= 1000
      append_key(source, {
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
    
  def get_mimes
    get_object.fetch(:mimes, {})
  end
    
  def init_object_mimes
    set_key(:mime, get_mimes)
  end

  def count_mime(mime)
    increment_subkey(:mimes, mime.to_sym)
  end
    
end

class ObjectHealthObjectAnalysis < ObjectHealthObjectComponent
  def initialize(ohobj, key)
    super(ohobj, key)
  end
      
  def default_object
    {}
  end

  def get_mimes
    get_object.fetch(:mimes, {})
  end

  def set_mimes(objmap)
    set_key(:mimes, objmap)
  end   
end

class ObjectHealthObjectTests < ObjectHealthObjectComponent
  def initialize(ohobj, key)
    super(ohobj, key)
  end
            
  def default_object
    tres = {failures: [], summary: '', test_run_log: []}
    ObjectHealth.status_values.each do |stat|
      tres[stat] = 0
    end
    tres
  end

  def record_test(name, status)
    set_key(name.to_sym, status)
    increment_key(status)
    append_key(:failures, name) if status == :FAIL
  end    
end