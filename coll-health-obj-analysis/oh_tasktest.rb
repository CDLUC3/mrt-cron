require 'json'

class ObjHealthTask
  def initialize(oh, taskdef, name)
    @oh = oh
    @taskdef = taskdef
    @name = name
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

  def run_task(obj)
    obj.get_analysis
  end
end

class ObjHealthTest < ObjHealthTask
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def run_test(obj)
    #Random.new.rand(4) == 0 ? :FAIL : :PASS
    :SKIP
  end
end