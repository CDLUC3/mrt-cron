require 'json'
require 'mysql2'
require 'nokogiri'
require 'mustache'
require_relative 'oh_object'

class ObjectHealthDb
  def initialize(config, mode, cliparams)
    nullquery = 'and 0 = 1'
    @config = config
    @dbconf = @config.fetch('dbconf', {})
    gather = @config.fetch('gather-ids', {})
    @cliparams = cliparams
    select = gather.fetch('select', 'select 1 where 1=1')
    exclusion = gather.fetch('default-exclusion', nullquery)
    exclusion = gather.fetch('build-exclusion', 'limit {{LIMIT}}') if mode == :build
    exclusion = gather.fetch('analysis-exclusion', 'limit {{LIMIT}}') if mode == :analysis
    exclusion = gather.fetch('tests-exclusion', 'limit {{LIMIT}}') if mode == :tests
    defq = cliparams.fetch(:QUERY, 'collection')
    @queries = []
    q = gather.fetch('queries', {}).fetch(defq, nullquery)
    sql = add_user_params_to_sql("#{select} #{q} #{exclusion}")
    @queries.append(sql)
  end

  def add_user_params_to_sql(q)
    Mustache.render(q, @cliparams)
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
      puts q
      stmt = conn.prepare(q)
      stmt.execute(*[]).each do |r|
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
      ohobj.build.build_object_representation(r)
    end
    conn.close
    ohobj
  end

  def process_object_sidecar(ohobj)
    sql = get_object_sidecar_sql
    conn = get_db_cli
    stmt = conn.prepare(sql)
    stmt.execute(*[ohobj.id]).each do |r|
      ohobj.build.set_sidecar(r.fetch('value', ''))
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
      ohobj.build.process_object_file(r)
    end
    conn.close
    ohobj
  end

  def update_object_build(ohobj)
    loaded = false
    sql = %{select 1 from object_health_json where inv_object_id=?}
    conn = get_db_cli
    stmt = conn.prepare(sql)
    stmt.execute(*[ohobj.id]).each do |r|
      loaded = true
    end
    conn.close

    if loaded
      sql = %{
        update object_health_json
        set build=?, build_updated = now()
        where inv_object_id = ?;
      }
      conn = get_db_cli
      stmt = conn.prepare(sql)
      stmt.execute(*[ohobj.build.to_json, ohobj.id])
      conn.close
    else
      sql = %{
        insert into object_health_json(inv_object_id, build, build_updated)
        values(?, ?, now());
      }
      conn = get_db_cli
      stmt = conn.prepare(sql)
      stmt.execute(*[ohobj.id, ohobj.build.to_json])
      conn.close
    end
  end

  def update_object_analysis(ohobj)
    sql = %{
      update object_health_json
      set analysis=?, analysis_updated = now()
      where inv_object_id = ?;
    }
    conn = get_db_cli
    stmt = conn.prepare(sql)
    stmt.execute(*[ohobj.analysis.to_json, ohobj.id])
    conn.close
  end

  def update_object_tests(ohobj)
    sql = %{
      update object_health_json
      set tests=?, tests_updated = now()
      where inv_object_id = ?;
    }
    conn = get_db_cli
    stmt = conn.prepare(sql)
    stmt.execute(*[ohobj.tests.to_json, ohobj.id])
    conn.close
  end

  def clear_object_health(mode)
    sql = ""
    if mode == :build
      sql = %{
        update object_health_json
        set build=null, build_updated=null, analysis=null, analysis_updated=null, tests=null, tests_updated=null
      }
    end
    if mode == :analysis
      sql = %{
        update object_health_json
        set analysis=null, analysis_updated=null, tests=null, tests_updated=null
      }
    end
    if mode == :tests
      sql = %{
        update object_health_json
        set tests=null, tests_updated=null
      }
    end
    unless sql.empty?
      puts sql
      conn = get_db_cli
      stmt = conn.prepare(sql)
      stmt.execute(*[])
      conn.close
    end
  end


  def load_object_json(ohobj)
    sql = %{
      select 
        cast(build as binary) build,
        build_updated,
        cast(analysis as binary) analysis,
        analysis_updated,
        cast(tests as binary) tests,
        tests_updated
      from object_health_json where inv_object_id = ?;
    }
    conn = get_db_cli
    stmt = conn.prepare(sql)
    stmt.execute(*[ohobj.id]).each do |r|
      ohobj.build.set_object_from_json(r.values[0], r.values[1])
      ohobj.analysis.set_object_from_json(r.values[2], r.values[3])
      ohobj.tests.set_object_from_json(r.values[4], r.values[5])
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
