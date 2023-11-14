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
    return ohobj if ohobj.analysis.get_object.fetch(:merritt_test_data, false)
    map = {}
    objmap = {}
    objmap_ext_mismatch = {}
    ObjectHealth.status_values.each do |stat|
      objmap[stat] = []
    end
    ohobj.build.get_object.fetch(:mimes_for_object, []).each do |rec|
      mime = rec.fetch(:mime, '').to_sym
      next if mime.empty?
      status = @statmap.fetch(mime, :SKIP)
      # if mime contains a semicolon, try performing a match on the substring before the semicolon
      if status == :SKIP && mime.to_s =~ %r[;]
        tmime = mime.to_s.split(";")[0].to_sym
        tstatus = @statmap.fetch(tmime, :SKIP)
        if tstatus != :SKIP
          mime = tmime
          status = tstatus
        end
      end
      map[mime] = status
    end
    map.each do |k,v|
      objmap[v].append(k)
    end
    ohobj.analysis.set_key(:mimes_by_status, objmap)

    ohobj.build.get_object.fetch(:producer, []).each do |f|
      next if f.fetch(:ignore_file, false)
      ext = f.fetch(:ext, "").to_sym

      mime = f.fetch(:mime_type, '').to_sym
      unless ext.empty?
        unless @mimeext.fetch(mime, []).include?(ext.to_s)
          objmap_ext_mismatch[mime] = objmap_ext_mismatch.fetch(mime, {})
          objmap_ext_mismatch[mime][ext] = objmap_ext_mismatch.fetch(mime, {}).fetch(ext, []).append(f.fetch(:pathname, ''))
        end
      end
    end
    arr = []
    objmap_ext_mismatch.each do |mime,v|
      objmap_ext_mismatch[mime].each do |ext, arr|
        ohobj.analysis.append_key(:mime_ext_mismatch, {
          mime: mime,
          ext: ext,
          key: "#{mime}: #{ext}", 
          count: arr.length,
          files: arr
        })
      end
    end

    ohobj
  end
end