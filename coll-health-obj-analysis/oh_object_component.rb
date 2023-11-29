require 'json'
require 'time'

class ObjectHealthObjectComponent
  def initialize(ohobj, key)
    @updated = nil
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

  def set_object_from_json(json, updated)
    set_object(JSON.parse(json, symbolize_names: true)) unless json.nil?
    @updated = ObjectHealthObject.make_opensearch_date(updated)
  end

  def pretty_json
    JSON.pretty_generate(get_object)
  end    

  def set_key(key, val)
    @ohobj.set_key(@compkey, key, val)
  end

  def set_subkey(key, subkey, val)
    @ohobj.set_subkey(@compkey, key, subkey, val)
  end

  def append_key(key, val)
    @ohobj.append_key(@compkey, key, val)
  end

  def append_subkey(key, subkey, val)
    @ohobj.append_subkey(@compkey, key, subkey, val)
  end

  def increment_key(key)
    @ohobj.increment_key(@compkey, key)
  end

  def zero_subkey(key, subkey)
    @ohobj.zero_subkey(@compkey, key, subkey)
  end

  def increment_subkey(key, subkey)
    @ohobj.increment_subkey(@compkey, key, subkey)
  end

  def concat_key(key, str)
    @ohobj.concat_key(@compkey, key, str)
  end

  def loaded?
    !@updated.nil?
  end
end

class ObjectHealthObjectBuild < ObjectHealthObjectComponent
  def initialize(ohobj, key)
    super(ohobj, key)
  end

  def default_object
    {
      id: @ohobj.id
    }
  end

  def build_object_representation(r)
    loc = r.fetch('localids', '')
    loc = '' if loc.nil?
    set_key(:identifiers, {
      ark: r.fetch('ark', ''),
      localids: loc.split(',')
    })
    m = r.fetch('mnemonic', '')
    set_key(:containers, {
      owner_ark: r.fetch('owner_ark', ''),
      owner_name: r.fetch('owner_name', ''),
      coll_ark: r.fetch('coll_ark', ''),
      coll_name: r.fetch('coll_name', ''),
      mnemonic: m,
      campus: campus(r.fetch('coll_name', ''))
    })
    set_key(:metadata, {
      erc_who: r.fetch('erc_who', ''),
      erc_what: r.fetch('erc_what', ''),
      erc_when: r.fetch('erc_when', ''),
      erc_where: r.fetch('erc_where', '')
    })
    set_key(:modified, ObjectHealthObject.make_opensearch_date(r.fetch('modified', '')))
    set_key(:embargo_end_date, ObjectHealthObject.make_opensearch_date(r.fetch('embargo_end_date', '')))
    @updated = DateTime.now.to_s
  end

  def campus(cname)
    return "CDL" if cname =~ %r[^(CDL|UC3)]
    return "UCB" if cname =~ %r[(^UCB |Berkeley)]
    return "UCD" if cname =~ %r[^UCD]
    return "UCLA" if cname =~ %r[^UCLA]
    return "UCSB" if cname =~ %r[^UCSB]
    return "UCI" if cname =~ %r[^UCI]
    return "UCM" if cname =~ %r[^UCM]
    return "UCR" if cname =~ %r[^UCR]
    return "UCSC" if cname =~ %r[^UCSC]
    return "UCSD" if cname =~ %r[^UCSD]
    return "UCSF" if cname =~ %r[^UCSF]
    "Other"
  end

  def self.make_sidecar(sidecarText)
    sidecar = {}
    return sidecar if sidecarText.nil?
    return sidecar if sidecarText.empty?
    begin
      xml = Nokogiri::XML(sidecarText).remove_namespaces!
      xml.xpath("//*[not(descendant::*)]").each do |n|
        text = n.text.strip.gsub("\\n","").gsub("\n", "").strip
        sidecar[n.name] = sidecar.fetch(n.name, []).append(text) unless text.empty?
      end
    rescue => exception
      puts exception
    end
    sidecar
  end

  def clear_sidecar
    set_key(:sidecar, [])
  end

  def set_sidecar(text)
    append_key(:sidecar, ObjectHealthObjectBuild.make_sidecar(text))
  end

  def process_object_files(ofiles, version)
    set_key(:file_counts, {deleted: 0, empty: 0})
    set_key(:producer, [])
    set_key(:system, [])
    set_key(:na, [])
    set_key(:version, version)
    ofiles.each do |k,v|
      source = v.fetch(:source, :na).to_sym
      increment_subkey(:file_counts, source)
      # since we only record the first 1000 files for an object, this cannot be peformed at analysis time
      if v[:last_version_present] < version
        increment_subkey(:file_counts, :deleted) 
        v[:deleted] = true
      end

      if v[:billable_size] == 0
        increment_subkey(:file_counts, :empty) 
        v[:empty] = true
      end

      if @ohobj.check_ignore_file(v[:pathname])
        v[:ignore_file] = true
        append_key(:ignore_files, v[:pathname])
      end

      # count mime type for all files
      mime = v[:mime_type]
      if source == :producer and !mime.empty?
        count_mime(mime)
      end

      # record up to 1000 files for the object
      if get_object.fetch(source, []).length <= 1000
        append_key(source, v)
      end
    end
  end

  def process_object_file(ofiles, r)
    pathname = r.fetch('pathname', '')
    version = 0
    unless pathname.empty?
      full_size = r.fetch('full_size', 0)
      billable_size = r.fetch('billable_size', 0)
      version = r.fetch('number', 0)
      ext = ""
      
      ext = pathname.downcase.split(".")[-1] if pathname =~ %r[\.]
      if ext.empty?
        pathtype = :na
      elsif ext =~ %r[^([a-z][a-z0-9]{1,4})$]
        pathtype = :file
      elsif ext =~ %r[[\/\?]]
        ext = ext.gsub(%r[[\/\?].*$], '')
        pathtype = :url
        ext = "" unless ext =~ %r[^([a-z][a-z0-9]{1,4})$]
      else
        pathtype = :na
        ext = ""
      end
      
      v = {
        version: version,
        last_version_present: version,
        source: r.fetch('source', ''),
        pathname: pathname,
        billable_size: billable_size,
        mime_type: r.fetch('mime_type', ''),
        digest_type: r.fetch('digest_type', ''),
        digest_value: r.fetch('digest_value', ''),
        created: ObjectHealthObject.make_opensearch_date(r.fetch('created', '')),
        pathtype: pathtype
      }
      v[:ext] = ext unless ext.empty?
      ofiles[pathname] = v unless ofiles.key?(pathname)
      if full_size == billable_size
        ofiles[pathname] = v
      else
        ofiles[pathname][:last_version_present] = version
      end
    end
    version
  end
    
  def count_mime(mime)
    get_object[:mimes_for_object] = [] unless get_object.key?(:mimes_for_object)
    arr = get_object[:mimes_for_object]
    arr.each_with_index do |r,i|
      if r.fetch(:mime, '') == mime
        arr[i][:count] = arr[i].fetch(:count, 0) + 1
        return
      end
    end
    arr.append({mime: mime, count: 1})
  end
    
end

class ObjectHealthObjectAnalysis < ObjectHealthObjectComponent
  def initialize(ohobj, key)
    super(ohobj, key)
  end
      
  def default_object
    {}
  end
end

class ObjectHealthObjectTests < ObjectHealthObjectComponent
  def initialize(ohobj, key)
    super(ohobj, key)
  end
            
  def default_object
    tres = {failures: [], summary: [], results: {}, counts: {}}
    ObjectHealthUtil.status_values.each do |stat|
      tres[:counts][stat] = 0
    end
    tres
  end

  def record_test(name, status)
    set_subkey(:results, name.to_sym, status)
    increment_subkey(:counts, status)
    append_subkey(:by_status, status, name)
    #append_key(:failures, name) if status == :FAIL
  end    
end