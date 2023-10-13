require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class MimeTask < ObjHealthTask
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
    @statmap = {}
    ObjectHealth.status_values.each do |stat|
      taskdef.fetch(stat.to_s, []).each do |mime|
        @statmap[mime] = stat 
      end
    end
  end

  def run_task(obj)
    map = {}
    objmap = {}
    ObjectHealth.status_values.each do |stat|
      objmap[stat] = []
    end
    obj.fetch(:mimes, []).each do |mime|
      map[mime] = @statmap.fetch(mime, :SKIP) unless mime.empty?
    end
    map.each do |k,v|
      objmap[v].append(k)
    end
    obj[:analysis][:mime] = objmap
    obj
  end
end