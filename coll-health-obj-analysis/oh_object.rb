class ObjectHealthObject
  def initialize(build_config, id)
    @id = id
    @osobj = {
      id: id,
      '@timestamp': Time.now.strftime("%Y-%m-%dT%H:%M:%S%z")
    }
    @build_config = build_config
  end

  def init_components
    @build = ObjectHealthObjectBuild.new(self, :build)
    @build.init_object
    @analysis = ObjectHealthObjectAnalysis.new(self, :analysis)
    @analysis.init_object
    @tests = ObjectHealthObjectTests.new(self, :tests)
    @tests.init_object
  end

  def build
    @build
  end

  def analysis
    @analysis
  end

  def tests
    @tests
  end

  def self.make_opensearch_date(modt)
    return '' if modt.nil?
    return '' if modt.to_s.empty?
    DateTime.parse("#{modt} -0700").to_s
  end

  def to_json
    @osobj.to_json
  end

  def get_osobj
    @osobj
  end

  def id
    @osobj.fetch(:id, 0)
  end

  def mnemonic
    @osobj[:build].fetch(:containers, {}).fetch(:mnemonic, "")
  end

  def ark
    @osobj[:build].fetch(:identifiers, {}).fetch(:ark, "")
  end

  def localids
    @osobj[:build].fetch(:identifiers, {}).fetch(:localids, [])
  end

  def first_localid
    localids.empty? ? "" : localids[0]
  end


  def set_key(compkey, key, val)
    @osobj[compkey][key] = val
  end
    
  def set_subkey(compkey, key, subkey, val)
    @osobj[compkey][key] =  {} unless @osobj[compkey].key?(key)
    @osobj[compkey][key][subkey] = val
  end

  def append_key(compkey, key, val)
    @osobj[compkey][key] = [] unless @osobj[compkey].key?(key)
    @osobj[compkey][key].append(val)
  end

  def append_subkey(compkey, key, subkey, val)
    @osobj[compkey][key] =  {} unless @osobj[compkey].key?(key)
    @osobj[compkey][key][subkey] = [] unless @osobj[compkey][key].key?(subkey)
    @osobj[compkey][key][subkey].append(val)
  end

  def increment_key(compkey, key)
    @osobj[compkey][key] = @osobj[compkey].fetch(key, 0) + 1
  end

  def zero_subkey(compkey, key, subkey)
    @osobj[compkey][key] = {} unless @osobj[compkey].key?(key)
    @osobj[compkey][key][subkey] = 0
  end

  def increment_subkey(compkey, key, subkey)
    @osobj[compkey][key] = {} unless @osobj[compkey].key?(key)
    @osobj[compkey][key][subkey] = @osobj[compkey][key].fetch(subkey, 0) + 1
  end

  def concat_key(compkey, key, str)
    s = @osobj[compkey].fetch(key, '')
    ss = s.empty? ? str : "#{s}; #{str}"
    @osobj[compkey][key] = ss 
  end

  def template_map 
    identifiers = build.get_object.fetch(:identifiers, {})
    locid = identifiers.fetch(:localids, [])
    ark = identifiers.fetch(:ark, "")
    map = {}
    map[:ARK] = ark unless ark.empty?
    map[:LOCALID] = locid[0] unless locid.empty?
    map
  end 

  def check_ignore_file(pathname)
    ObjectHealth.match_criteria(criteria: @build_config.fetch(:ignore_files, {}), key: pathname, ohobj: self, criteria_list: :paths, criteria_patterns: :patterns)
  end

end