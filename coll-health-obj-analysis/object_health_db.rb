# frozen_string_literal: true

require 'json'
require 'mysql2'
require 'nokogiri'
require 'mustache'
require_relative 'oh_object'

class ObjectHealthDb
  DEFQ = 'select 1 where 1=1'
  def initialize(objh, config, mode)
    @oh = objh
    nullquery = 'and 0 = 1'
    @config = config
    @dbconf = @config.fetch(:dbconf, {})
    gather = @config.fetch(:gather_ids, {})
    @cliparams = objh.options.fetch(:query_params, {})
    iterative_params = objh.options.fetch(:iterative_params, {})
    select = gather.fetch(:select, DEFQ)

    if @cliparams.fetch(:QUERY, '') == 'id'
      exclusion = ''
    else
      exclusion = gather.fetch(:default_exclusion, nullquery)
      exclusion = gather.fetch(:build_exclusion, 'limit {{LIMIT}}') if mode == :build
      exclusion = gather.fetch(:analysis_exclusion, 'limit {{LIMIT}}') if mode == :analysis
      exclusion = gather.fetch(:tests_exclusion, 'limit {{LIMIT}}') if mode == :tests
    end
    defq = @cliparams.fetch(:QUERY, 'collection').to_sym
    @queries = []
    q = gather.fetch(:queries, {}).fetch(defq, nullquery)
    iterative_params.each do |itp|
      sql = add_user_params_to_sql("#{select} #{q} #{exclusion}", itp)
      @queries.append(sql)
    end

    clearq = @cliparams.fetch(:QUERY, 'default').to_sym
    q = gather.fetch(:clear_queries, {}).fetch(clearq, '')
    @clearquery = Mustache.render(q, @cliparams)
  end

  def add_user_params_to_sql(q, iterative_param)
    Mustache.render(q, @cliparams.merge(iterative_param))
  end

  def clear_query
    @clearquery
  end

  attr_reader :queries

  def db_cli
    Mysql2::Client.new(
      host: @dbconf[:host],
      username: @dbconf[:username],
      database: @dbconf[:database],
      password: @dbconf[:password],
      port: @dbconf[:port],
      encoding: @dbconf.fetch(:encoding, 'utf8mb4'),
      collation: @dbconf.fetch(:collation, 'utf8mb4_unicode_ci')
    )
  end

  def hash_object_list
    list = []
    conn = db_cli
    @queries.each do |q|
      puts q if @oh.debug
      stmt = conn.prepare(q)
      stmt.execute.each do |r|
        list.append(r.values[0])
      end
    end
    conn.close
    puts "\n** #{list.length} to process\n" if @oh.verbose
    list
  end

  def hash_object_sql
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
        own.name as owner_name,
        c.name as coll_name
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

  def hash_object_sidecar_sql
    %(
      select value from inv.inv_metadatas where inv_object_id = ?;
    )
  end

  def process_object_metadata(ohobj)
    sql = hash_object_sql
    conn = db_cli
    stmt = conn.prepare(sql)
    stmt.execute(ohobj.id).each do |r|
      ohobj.build.build_object_representation(r)
    end
    conn.close
    ohobj
  end

  def process_object_sidecar(ohobj)
    ohobj.build.clear_sidecar
    sql = hash_object_sidecar_sql
    conn = db_cli
    stmt = conn.prepare(sql)
    stmt.execute(ohobj.id).each do |r|
      ohobj.build.append_sidecar(r.fetch('value', ''))
    end
    conn.close
    ohobj
  end

  def hash_object_files_sql
    # TODO: Identify deletions - file not in the current version
    %(
      select
        v.number,
        f.pathname,
        f.source,
        f.billable_size,
        f.full_size,
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
      order by
        v.number,
        f.pathname
      ;
    )
  end

  def process_object_files(ohobj)
    ofiles = {}
    sql = hash_object_files_sql

    conn = db_cli
    stmt = conn.prepare(sql)
    version = 0
    stmt.execute(ohobj.id).each do |r|
      version = ohobj.build.process_object_file(ofiles, r)
    end
    conn.close
    ohobj.build.process_object_files(ofiles, version)
    ohobj
  end

  def update_object_build(ohobj)
    loaded = false
    sql = %(select 1 from object_health_json where inv_object_id=?)
    conn = db_cli
    stmt = conn.prepare(sql)
    stmt.execute(ohobj.id).each do |_r|
      loaded = true
    end
    conn.close

    if loaded
      sql = %{
        update object_health_json
        set build=?, build_updated = now()
        where inv_object_id = ?;
      }
      conn = db_cli
      stmt = conn.prepare(sql)
      stmt.execute(ohobj.build.to_json, ohobj.id)
    else
      sql = %{
        insert into object_health_json(inv_object_id, build, build_updated)
        values(?, ?, now());
      }
      conn = db_cli
      stmt = conn.prepare(sql)
      stmt.execute(ohobj.id, ohobj.build.to_json)
    end
    conn.close
  end

  def update_object_analysis(ohobj)
    sql = %{
      update object_health_json
      set analysis=?, analysis_updated = now()
      where inv_object_id = ?;
    }
    conn = db_cli
    stmt = conn.prepare(sql)
    stmt.execute(ohobj.analysis.to_json, ohobj.id)
    conn.close
  end

  def update_object_tests(ohobj)
    sql = %{
      update object_health_json
      set tests=?, tests_updated = now()
      where inv_object_id = ?;
    }
    conn = db_cli
    stmt = conn.prepare(sql)
    stmt.execute(ohobj.tests.to_json, ohobj.id)
    conn.close
  end

  def update_object_exported(ohobj)
    sql = %{
      update object_health_json
      set exported = now()
      where inv_object_id = ?;
    }
    conn = db_cli
    stmt = conn.prepare(sql)
    stmt.execute(ohobj.id)
    conn.close
  end

  def status_query(where_clause = '')
    sql = %{
      select
        sum(case when build_updated is not null then 1 else 0 end) as built,
        sum(case when analysis_updated is not null then 1 else 0 end) as analyzed,
        sum(case when tests_updated is not null then 1 else 0 end) as tested,
        sum(case when build_updated is null then 1 else 0 end) as awaiting_rebuild,
        sum(case when analysis_updated is null or build_updated > analysis_updated then 1 else 0 end) as awaiting_analysis,
        sum(case when tests_updated is null or analysis_updated > tests_updated then 1 else 0 end) as awaiting_tests
      from
        object_health_json
      #{where_clause};
    }
    puts sql if @oh.debug
    conn = db_cli
    stmt = conn.prepare(sql)
    status = {}
    stmt.execute.each do |r|
      r.each do |k, v|
        status[k.to_sym] = v.to_i
      end
    end
    conn.close
    status
  end

  def object_health_status
    total_status = status_query
    status = status_query(@clearquery)

    if @oh.verbose
      puts '---------------------------------------------------'
      fmtstr = '%15<row>s %10<build>s %10<analysed>s %10<tested>s'
      puts format(formatstr, {
        row: '', 
        build: 'Build', 
        analyzed: 'Analysis', 
        tested: 'Tests'
      })
      puts format(formatstr, {
        row: 'Total Processed', 
        build: ObjectHealthUtil.num_format(total_status[:built]),
        analyzed: ObjectHealthUtil.num_format(total_status[:analyzed]),
        tested: ObjectHealthUtil.num_format(total_status[:tested])
      })
      puts format(formatstr, {
        row: 'Total Awaiting', 
        build: ObjectHealthUtil.num_format(total_status[:awaiting_rebuild]), 
        analyzed: ObjectHealthUtil.num_format(total_status[:awaiting_analysis]), 
        tested: ObjectHealthUtil.num_format(total_status[:awaiting_tests])
      })
      puts format(formatstr, {
        row:  'Query Processed', 
        build: ObjectHealthUtil.num_format(status[:built]), 
        analyzed: ObjectHealthUtil.num_format(status[:analyzed]), 
        tested: ObjectHealthUtil.num_format(status[:tested])
      })
      puts format(formatstr, {
        row: 'Query Awaiting', 
        build: ObjectHealthUtil.num_format(status[:awaiting_rebuild]), 
        analyzed: ObjectHealthUtil.num_format(status[:awaiting_analysis]), 
        tested: ObjectHealthUtil.num_format(status[:awaiting_tests])
      })
      puts '---------------------------------------------------'
    end

    status
  end

  def clear_object_health(mode)
    sql = ''
    if mode == :build
      sql = %(
        update object_health_json
        set build=null, build_updated=null, analysis=null, analysis_updated=null, tests=null, tests_updated=null
        #{@clearquery}
      )
    end
    if mode == :analysis
      sql = %(
        update object_health_json
        set analysis=null, analysis_updated=null, tests=null, tests_updated=null
        #{@clearquery}
      )
    end
    if mode == :tests
      sql = %(
        update object_health_json
        set tests=null, tests_updated=null
        #{@clearquery}
      )
    end
    unless sql.empty?
      puts sql if @oh.debug
      conn = db_cli
      stmt = conn.prepare(sql)
      stmt.execute
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
    conn = db_cli
    stmt = conn.prepare(sql)
    stmt.execute(ohobj.id).each do |r|
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
