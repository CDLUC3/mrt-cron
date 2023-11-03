require 'json'

class ObjHealthTask
  def initialize(oh, taskdef, name)
    @oh = oh
    @taskdef = taskdef
    scope = @taskdef.fetch(:collection_scope, {})
    @skip = scope.fetch(:skip, [])
    @apply = scope.fetch(:apply, [])
    @name = name
  end

  def check_scope(ohobj)
    m = ohobj.mnemonic
    return true if @apply.include?(m)
    return false if @skip.include?(m)
    @oh.collection_taxonomy(m).each do |g|
      return true if @apply.include?(g)
      return false if @skip.include?(g)
    end
    true
  end

  def name
    @name
  end
  
  def self.create(oh, taskdef, name)
    unless taskdef.nil?
      taskclass = taskdef.fetch(:class, '')
      unless taskclass.empty?
        Object.const_get(taskclass).new(oh, taskdef, name)
      end
    end
  end

  def run_task(ohobj)
    ohobj.analysis
  end

  def inspect
    self.to_s
  end

end

class ObjHealthTest < ObjHealthTask
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def run_test(ohobj)
    :SKIP
  end

  def report_status(condition: nil)
    @taskdef.fetch(:report_status, {}).each do |k,v|
      return k if condition.nil? || v.nil?
      return k if condition == v.to_sym
      return k if condition == v
    end
    :SKIP
  end
end