require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class MimeTask < ObjHealthTask
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
    @statmap = {}
    ObjectHealth.status_values.each do |stat|
      taskdef.fetch(stat.to_s, []).each do |mime|
        @statmap[mime.to_sym] = stat 
      end
    end
  end

  def run_task(ohobj)
    map = {}
    objmap = {}
    ObjectHealth.status_values.each do |stat|
      objmap[stat] = []
    end
    ohobj.get_object_mimes.each do |mime,v|
      map[mime.to_sym] = @statmap.fetch(mime.to_sym, :SKIP) unless mime.empty?
    end
    map.each do |k,v|
      objmap[v].append(k)
    end
    ohobj.set_analysis_mimes(objmap)
    ohobj
  end
end