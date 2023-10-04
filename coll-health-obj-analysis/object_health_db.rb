require 'json'
require 'mysql2'
require 'nokogiri'

class ObjectHealthDb
  def initialize(dbconf)
    @dbconf = dbconf
  end

  def get_db_cli
    Mysql2::Client.new(
      :host => @dbconf['host'],
      :username => @dbconf['username'],
      :database=> @dbconf['database'],
      :password=> @dbconf['password'],
      :port => @dbconf['port'],
      :encoding => @dbconf.fetch('encoding', 'utf8mb4'),
      :collation => @dbconf.fetch('collation', 'utf8mb4_unicode_ci'),
    )
  end
  
  def get_objects_sql
    %{
      select
        o.id
      from
        inv.inv_objects o
      inner join
        inv.inv_collections_inv_objects icio
      on
        icio.inv_object_id = o.id
      inner join
        inv.inv_collections c
      on 
        c.id = icio.inv_collection_id
      
      where 
        c.mnemonic = 'merritt_demo'
      and 
        exists (select 1 from inv.inv_metadatas where inv_object_id=o.id)
      
      order by 
        o.modified desc
      limit 10
    }
  end

  def get_object_list
    list = []
    stmt = get_db_cli.prepare(get_objects_sql)
    stmt.execute().each do |r|
      list.append(r.values[0])
    end
    list
  end

  def get_object_sql
    %{
      select
        o.id as id,
        o.ark as ark,
        own.ark as owner_ark,
        c.ark as coll_ark,
        c.mnemonic,
        o.erc_who,
        o.erc_what,
        o.erc_when,
        o.erc_where,
        o.modified,
        (select group_concat(ifnull(local_id, '')) from inv.inv_localids where inv_object_ark = o.ark) as localids,
        (select ifnull(embargo_end_date, '') from inv.inv_embargoes where inv_object_id = o.id) as embargo_end_date,
        (select value from inv.inv_metadatas where inv_object_id=o.id limit 1) as metadata
      from
        inv.inv_objects o
      inner join
        inv.inv_collections_inv_objects icio
      on
        icio.inv_object_id = o.id
      inner join
        inv.inv_collections c
      on 
        c.id = icio.inv_collection_id
      inner join
        inv.inv_owners own
      on 
        own.id = o.inv_owner_id
      where 
        o.id = ?
      ;
    }
  end

  def make_sidecar(sidecarText)
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

  def make_opensearch_date(modt)
    return '' if modt.nil?
    return '' if modt.to_s.empty?
    DateTime.parse("#{modt} -0700").to_s
  end

  def process_object_metadata(id)
    obj = {id: id}
    sql = get_object_sql
    stmt = get_db_cli.prepare(sql)
    stmt.execute(*[id]).each do |r|
      loc = r.fetch('localids', '')
      loc = '' if loc.nil?
      obj[:identifiers] = {
        ark: r.fetch('ark', ''),
        localids: loc.split(',')
      }
      obj[:containers] = {
        owner_ark: r.fetch('owner_ark', ''),
        coll_ark: r.fetch('coll_ark', ''),
        mnemonic: r.fetch('mnemonic', '')
      }

      obj[:metadata] = {
        erc_who: r.fetch('erc_who', ''),
        erc_what: r.fetch('erc_what', ''),
        erc_when: r.fetch('erc_when', ''),
        erc_where: r.fetch('erc_where', ''),
        sidecar: make_sidecar(r.fetch('metadata', ''))
      }
      obj['@timestamp'] = make_opensearch_date(r.fetch('modified', ''))
      obj[:modified] = make_opensearch_date(r.fetch('modified', ''))
      obj[:embargo_end_date] = make_opensearch_date(r.fetch('embargo_end_date', ''))
    end
    obj
  end

  def get_object_files_sql
    %{
      select
        v.number,
        f.pathname,
        f.source,
        f.billable_size,
        f.mime_type,
        f.digest_type,
        f.digest_value,
        f.created
      from
        inv.inv_files f
      inner join
        inv.inv_versions v
      on
        f.inv_version_id = v.id
      where 
        f.inv_object_id = ?
      and
        f.full_size = f.billable_size
      order by
        v.number, 
        f.pathname
      ;
    }
  end

  def process_object_files(id, obj)
    sql = get_object_files_sql

    obj[:system] = []
    obj[:producer] = []
    stmt = get_db_cli.prepare(sql)
    stmt.execute(*[id]).each do |r|
      source = r.fetch('source', 'na').to_sym
      obj[source].push({
        version: r.fetch('number', 0),
        pathname: r.fetch('pathname', ''),
        billable_size: r.fetch('billable_size', 0),
        mime_type: r.fetch('mime_type', ''),
        digest_type: r.fetch('digest_type', ''),
        digest_value: r.fetch('digest_value', ''),
        created: r.fetch('created', '')
      })
    end
    obj
  end

  def update_object(id, obj)
    sql = %{
      replace into object_health_json(inv_object_id, object_health)
      values(?, ?);
    }
    stmt = get_db_cli.prepare(sql)
    stmt.execute(*[id, obj.to_json])
  end

  def get_object(id)
    obj = process_object_metadata(id)
    obj = process_object_files(id, obj)
    obj
  end
end
