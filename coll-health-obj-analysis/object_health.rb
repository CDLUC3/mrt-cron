require 'json'
require 'yaml'
require 'uc3-ssm'
require 'mysql2'

class ObjectHealth
  def initialize
    config_file = 'config/database.ssm.yml'
    @config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: config_file, resolve_key: 'default', return_key: 'default')
    @dbconf = @config.fetch('dbconf', {})
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
  
  def processObjects
    sql = %{
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
      order by 
        o.modified
      limit 1
    }
    stmt = get_db_cli.prepare(sql)
    stmt.execute().each do |r|
      id = r.fetch('id', -1)
      processObject(id)
    end
  end

  def processObject(id)
    obj = {id: id}
    sql = %{
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
          (select ifnull(embargo_end_date, '') from inv.inv_embargoes where inv_object_id = o.id) as embargo_end_date
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
    stmt = get_db_cli.prepare(sql)
    stmt.execute(*[id]).each do |r|
      obj[:identifiers] = {
        ark: r.fetch('ark', ''),
        localids: r.fetch('localids', '').split(',')
      }
      obj[:identifiers] = {
        owner_ark: r.fetch('owner_ark', ''),
        coll_ark: r.fetch('coll_ark', ''),
        mnemonic: r.fetch('mnemonic', '')
      }
      obj[:metadata] = {
        erc_who: r.fetch('erc_who', ''),
        erc_what: r.fetch('erc_what', ''),
        erc_when: r.fetch('erc_when', ''),
        erc_where: r.fetch('erc_where', '')  
      }
      obj[:modified] = r.fetch('modified', '')
      obj[:embargo_end_date] = r.fetch('embargo_end_date', '')
    end

    sql = %{
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
    
    sql = %{
      replace into object_health_json(inv_object_id, object_health)
      values(?, ?);
    }
    stmt = get_db_cli.prepare(sql)
    stmt.execute(*[id, obj.to_json])
  end
end

oh = ObjectHealth.new
oh.processObjects