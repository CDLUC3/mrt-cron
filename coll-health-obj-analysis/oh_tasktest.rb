require 'json'

class ObjHealthTask
  def initialize(oh, taskdef, name)
    @oh = oh
    @taskdef_with_sym = JSON.parse(taskdef.to_json, symbolize_names: true)
    scope = @taskdef_with_sym.fetch(:collection_scope, {})
    @skip = scope.fetch(:skip, [])
    @apply = scope.fetch(:apply, [])
    @name = name
  end

  def check_scope(ohobj)
    m = ohobj.mnemonic
    colltax = @oh.collection_taxonomy(m)
    if @apply.length > 0
      return @apply.include?(m) || @apply.include(colltax)
    elsif @skip.length > 0
      return !(@skip.include?(m) || @skip.include?(colltax))
    end
    true
  end

  def name
    @name
  end
  
  def self.create(oh, taskdef, name)
    unless taskdef.nil?
      taskclass = taskdef.fetch('class', '')
      unless taskclass.empty?
        Object.const_get(taskclass).new(oh, taskdef, name)
      end
    end
  end

  def run_task(ohobj)
    ohobj.analysis
  end
end

class ObjHealthTest < ObjHealthTask
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def run_test(ohobj)
    #Random.new.rand(4) == 0 ? :FAIL : :PASS
    :SKIP
  end
end