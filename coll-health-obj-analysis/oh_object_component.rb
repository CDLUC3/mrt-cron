# frozen_string_literal: true

require 'json'
require 'time'

class ObjectHealthObjectComponent
  def initialize(ohobj, key)
    @updated = nil
    @ohobj = ohobj
    @compkey = key
    @ohobj.opensearch_obj[@compkey] = default_object
  end

  def default_object
    {}
  end

  def to_json(*_args)
    hash_object.to_json
  end

  def hash_object
    @ohobj.opensearch_obj[@compkey]
  end

  def set_object(obj)
    @ohobj.opensearch_obj[@compkey] = obj
  end

  def init_object
    set_object(default_object)
  end

  def set_object_from_json(json, updated)
    set_object(JSON.parse(json, symbolize_names: true)) unless json.nil?
    @updated = ObjectHealthObject.make_opensearch_date(updated)
  end

  def pretty_json
    JSON.pretty_generate(hash_object)
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
  def default_object
    {
      id: @ohobj.id
    }
  end

  def build_object_representation(row)
    loc = row.fetch('localids', '')
    loc = '' if loc.nil?
    set_key(
      :identifiers,
      {
        ark: row.fetch('ark', ''),
        localids: loc.split(',')
      }
    )
    m = row.fetch('mnemonic', '')
    set_key(
      :containers,
      {
        owner_ark: row.fetch('owner_ark', ''),
        owner_name: row.fetch('owner_name', ''),
        coll_ark: row.fetch('coll_ark', ''),
        coll_name: row.fetch('coll_name', ''),
        mnemonic: m,
        campus: campus(row.fetch('coll_name', ''))
      }
    )
    set_key(
      :metadata,
      {
        erc_who: row.fetch('erc_who', ''),
        erc_what: row.fetch('erc_what', ''),
        erc_when: row.fetch('erc_when', ''),
        erc_where: row.fetch('erc_where', '')
      }
    )
    set_key(:modified, ObjectHealthObject.make_opensearch_date(row.fetch('modified', '')))
    set_key(:embargo_end_date, ObjectHealthObject.make_opensearch_date(row.fetch('embargo_end_date', '')))
    @updated = DateTime.now.to_s
  end

  def campus(cname)
    return 'CDL' if cname =~ /^(CDL|UC3)/
    return 'UCB' if cname =~ /(^UCB |Berkeley)/
    return 'UCD' if cname =~ /^UCD/
    return 'UCLA' if cname =~ /^UCLA/
    return 'UCSB' if cname =~ /^UCSB/
    return 'UCI' if cname =~ /^UCI/
    return 'UCM' if cname =~ /^UCM/
    return 'UCR' if cname =~ /^UCR/
    return 'UCSC' if cname =~ /^UCSC/
    return 'UCSD' if cname =~ /^UCSD/
    return 'UCSF' if cname =~ /^UCSF/

    'Other'
  end

  def self.make_sidecar(sidecar_text)
    sidecar = {}
    return sidecar if sidecar_text.nil?
    return sidecar if sidecar_text.empty?

    begin
      xml = Nokogiri::XML(sidecar_text).remove_namespaces!
      xml.xpath('//*[not(descendant::*)]').each do |n|
        text = n.text.strip.gsub('\\n', '').gsub("\n", '').strip
        sidecar[n.name] = sidecar.fetch(n.name, []).append(text) unless text.empty?
      end
    rescue StandardError => e
      puts e
    end
    sidecar
  end

  def clear_sidecar
    set_key(:sidecar, [])
  end

  def append_sidecar(text)
    append_key(:sidecar, ObjectHealthObjectBuild.make_sidecar(text))
  end

  def process_object_files(ofiles, version)
    set_key(:file_counts, { deleted: 0, empty: 0 })
    set_key(:producer, [])
    set_key(:system, [])
    set_key(:na, [])
    set_key(:version, version)
    ofiles.each do |_k, v|
      source = v.fetch(:source, :na).to_sym
      increment_subkey(:file_counts, source)
      # since we only record the first 1000 files for an object, this cannot be peformed at analysis time
      if v[:last_version_present] < version
        increment_subkey(:file_counts, :deleted)
        v[:deleted] = true
      end

      if (v[:billable_size]).zero?
        increment_subkey(:file_counts, :empty)
        v[:empty] = true
      end

      if @ohobj.check_ignore_file(v[:pathname])
        v[:ignore_file] = true
        append_key(:ignore_files, v[:pathname])
      end

      # count mime type for all files
      mime = v[:mime_type]
      count_mime(mime) if (source == :producer) && !mime.empty?

      # record up to 1000 files for the object
      append_key(source, v) if hash_object.fetch(source, []).length <= 1000
    end
  end

  def process_object_file(ofiles, row)
    pathname = row.fetch('pathname', '')
    version = 0
    unless pathname.empty?
      full_size = row.fetch('full_size', 0)
      billable_size = row.fetch('billable_size', 0)
      version = row.fetch('number', 0)
      ext = ''

      ext = pathname.downcase.split('.')[-1] if pathname =~ /\./
      if ext.empty?
        pathtype = :na
      elsif ext =~ /^([a-z][a-z0-9]{1,4})$/
        pathtype = :file
      elsif ext =~ %r{[/?]}
        ext = ext.gsub(%r{[/?].*$}, '')
        pathtype = :url
        ext = '' unless ext =~ /^([a-z][a-z0-9]{1,4})$/
      else
        pathtype = :na
        ext = ''
      end

      v = {
        version: version,
        last_version_present: version,
        source: row.fetch('source', ''),
        pathname: pathname,
        billable_size: billable_size,
        mime_type: row.fetch('mime_type', ''),
        digest_type: row.fetch('digest_type', ''),
        digest_value: row.fetch('digest_value', ''),
        created: ObjectHealthObject.make_opensearch_date(row.fetch('created', '')),
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
    hash_object[:mimes_for_object] = [] unless hash_object.key?(:mimes_for_object)
    arr = hash_object[:mimes_for_object]
    arr.each_with_index do |r, i|
      if r.fetch(:mime, '') == mime
        arr[i][:count] = arr[i].fetch(:count, 0) + 1
        return
      end
    end
    arr.append({ mime: mime, count: 1 })
  end
end

class ObjectHealthObjectAnalysis < ObjectHealthObjectComponent
  def default_object
    {}
  end
end

class ObjectHealthObjectTests < ObjectHealthObjectComponent
  def default_object
    tres = { failures: [], summary: [], results: {}, counts: {} }
    ObjectHealthUtil.status_values.each do |stat|
      tres[:counts][stat] = 0
    end
    tres
  end

  def record_test(name, status)
    set_subkey(:results, name.to_sym, status)
    increment_subkey(:counts, status)
    append_subkey(:by_status, status, name)
    # append_key(:failures, name) if status == :FAIL
  end
end
