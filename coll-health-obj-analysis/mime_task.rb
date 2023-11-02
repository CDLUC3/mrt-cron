require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class MimeTask < ObjHealthTask
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
    @statmap = {}
    @mimeext = {}
    ObjectHealth.status_values.each do |stat|
      next if taskdef.fetch(stat, {}).nil?
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
    objmap_ext_mismatch = {}
    ObjectHealth.status_values.each do |stat|
      objmap[stat] = []
    end
    ohobj.build.get_object.fetch(:mimes_for_object, []).each do |rec|
      mime = rec.fetch(:mime, '').to_sym
      map[mime] = @statmap.fetch(mime, :SKIP) unless mime.empty?
    end
    map.each do |k,v|
      objmap[v].append(k)
    end
    ohobj.analysis.set_key(:mimes_by_status, objmap)

    ohobj.build.get_object.fetch(:producer, []).each do |f|
      ext = f.fetch(:ext, "").to_sym

      mime = f.fetch(:mime_type, '').to_sym
      unless ext.empty?
        unless @mimeext.fetch(mime, []).include?(ext.to_s)
          objmap_ext_mismatch[mime] = objmap_ext_mismatch.fetch(mime, {})
          objmap_ext_mismatch[mime][ext] = objmap_ext_mismatch.fetch(mime, {}).fetch(ext, 0) + 1
        end
      end
    end
    arr = []
    objmap_ext_mismatch.each do |mime,v|
      objmap_ext_mismatch[mime].each do |ext, count|
        arr.push({mime: mime, ext: ext, count: count})
      end
    end
    ohobj.analysis.set_key(:mime_ext_mismatch, arr)

    ohobj
  end
end