class ObjectHealthObject
  def initialize(id)
    @id = id
    @osobj = {
      id: id,
      '@timestamp': Time.now.strftime("%Y-%m-%dT%H:%M:%S%z")
    }
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

  def set_key(compkey, key, val)
    @osobj[compkey][key] = val
  end
    
  def append_key(compkey, key, val)
    @osobj[compkey][key] = [] unless @osobj[compkey].key?(key)
    @osobj[compkey][key].append(val)
  end
    
  def increment_key(compkey, key)
    @osobj[compkey][key] = @osobj[compkey].fetch(key, 0) + 1
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
end