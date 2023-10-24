require 'json'

class ObjHealthTask
  def initialize(oh, taskdef, name)
    @oh = oh
    @taskdef_with_sym = JSON.parse(taskdef.to_json, symbolize_names: true)
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