require 'json'
require 'mysql2'
require 'nokogiri'
require_relative 'oh_object'

class ObjectHealthDb
  def initialize(config)
    @config = config
    @dbconf = @config.fetch('dbconf', {})
    gather = @config.fetch('gather-ids', {})
    select = gather.fetch('select', 'select 1 where 1=1')
    exclusion = gather.fetch('exclusion', 'limit ?')
    @queries = []
    gather.fetch('queries', []).each do |q|
      @queries.append("#{select} #{q} #{exclusion}")
    end
    @limit = gather.fetch('limit', 10)
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
  
  def get_object_list
    list = []
    conn = get_db_cli
    @queries.each do |q|
      stmt = conn.prepare(q)
      stmt.execute(*[@limit]).each do |r|
        list.append(r.values[0])
      end
      break unless list.empty?
    end
    conn.close
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
  end

  def get_object_sidecar_sql
    %{
      select value from inv.inv_metadatas where inv_object_id = ?;
    }
  end



  def process_object_metadata(ohobj)
    sql = get_object_sql
    conn = get_db_cli
    stmt = conn.prepare(sql)
    stmt.execute(*[ohobj.id]).each do |r|
      ohobj.build_object_representation(r)
    end
    conn.close
    ohobj
  end

  def process_object_sidecar(ohobj)
    sql = get_object_sidecar_sql
    conn = get_db_cli
    stmt = conn.prepare(sql)
    stmt.execute(*[ohobj.id]).each do |r|
      ohobj.set_sidecar(r.fetch('value', ''))
    end
    conn.close
    ohobj
  end

  def get_object_files_sql
    # TODO: Identify deletions - file not in the current version
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

  def process_object_files(ohobj)
    # TODO: Identify deletions - file not in the current version
    sql = get_object_files_sql

    conn = get_db_cli
    stmt = conn.prepare(sql)
    stmt.execute(*[ohobj.id]).each do |r|
      ohobj.process_object_file(r)
    end
    conn.close
    ohobj
  end

  def update_object(ohobj)
    sql = %{
      replace into object_health_json(inv_object_id, object_health)
      values(?, ?);
    }
    conn = get_db_cli
    stmt = conn.prepare(sql)
    stmt.execute(*[ohobj.id, ohobj.to_json])
    conn.close
  end

  def load_object_json(ohobj)
    sql = %{
      select cast(object_health as binary) from object_health_json where inv_object_id = ?;
    }
    conn = get_db_cli
    stmt = conn.prepare(sql)
    stmt.execute(*[ohobj.id]).each do |r|
      ohobj.set_json(r.values[0])
    end
    conn.close
  end

  def build_object(ohobj)
    load_object_json(ohobj)
    process_object_metadata(ohobj)
    process_object_sidecar(ohobj)
    process_object_files(ohobj)
  end

end
