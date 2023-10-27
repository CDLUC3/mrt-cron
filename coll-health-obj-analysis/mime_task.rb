require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class MimeTask < ObjHealthTask
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
    @statmap = {}
    @mimeext = {}
    ObjectHealth.status_values.each do |stat|
      taskdef.fetch(stat, {}).each do |mime, exts|
        @statmap[mime] = stat
        @mimeext[mime] = exts 
      end
      cat = taskdef.fetch(:categorize, {})
    end
  end

  def run_task(ohobj)
    map = {}
    objmap = {}
    ObjectHealth.status_values.each do |stat|
      objmap[stat] = []
    end
    ohobj.build.get_mimes.each do |mime,v|
      map[mime] = @statmap.fetch(mime, :SKIP) unless mime.empty?
    end
    map.each do |k,v|
      objmap[v].append(k)
    end
    ohobj.analysis.set_mimes(objmap)
    ohobj
  end
end