# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class MimeTask < ObjHealthTask
  def initialize(objh, taskdef, name)
    super
    @statmap = {}
    @mimeext = {}
    ObjectHealthUtil.status_values.each do |stat|
      next if taskdef.fetch(stat, {}).nil?

      taskdef.fetch(stat, {}).each do |mime, exts|
        @statmap[mime] = stat
        @mimeext[mime] = exts
      end
      taskdef.fetch(:categorize, {})
    end
  end

  def run_task(ohobj)
    return ohobj if ohobj.analysis.hash_object.fetch(:merritt_test_data, false)

    map = {}
    objmap = {}
    objmap_ext_mismatch = {}
    objmap_ext_status = {}
    ObjectHealthUtil.status_values.each do |stat|
      objmap[stat] = []
    end
    ohobj.build.hash_object.fetch(:mimes_for_object, []).each do |rec|
      mime = rec.fetch(:mime, '').to_sym
      next if mime.empty?

      status = @statmap.fetch(mime, :SKIP)
      # if mime contains a semicolon, try performing a match on the substring before the semicolon
      if status == :SKIP && mime.to_s =~ /;/
        tmime = mime.to_s.split(';')[0].to_sym
        tstatus = @statmap.fetch(tmime, :SKIP)
        if tstatus != :SKIP
          mime = tmime
          status = tstatus
        end
      end
      map[mime] = status
    end
    map.each do |k, v|
      objmap[v].append(k)
    end
    ohobj.analysis.set_key(:mimes_by_status, objmap)

    ohobj.build.hash_object.fetch(:producer, []).each do |f|
      next if f.fetch(:ignore_file, false)

      ext = f.fetch(:ext, '').to_sym

      mime = f.fetch(:mime_type, '').to_sym
      next if ext.empty?

      cmimeext = @mimeext.fetch(mime, {})
      cmimeext = {} if cmimeext.nil?
      if cmimeext.key?(ext)
        cmimestat = cmimeext.fetch(ext, :PASS)
        cmimestat = cmimestat.nil? ? :PASS : cmimestat.to_sym
        unless cmimestat == :PASS
          objmap_ext_status[mime] = objmap_ext_status.fetch(mime, {})
          objmap_ext_status[mime][ext] = cmimestat
        end
      else
        objmap_ext_mismatch[mime] = objmap_ext_mismatch.fetch(mime, {})
        objmap_ext_mismatch[mime][ext] =
          objmap_ext_mismatch.fetch(mime, {}).fetch(ext, []).append(f.fetch(:pathname, ''))
      end
    end

    objmap_ext_mismatch.each_key do |mime|
      objmap_ext_mismatch[mime].each do |ext, arr|
        ohobj.analysis.append_key(
          :mime_ext_mismatch,
          {
            mime: mime,
            ext: ext,
            key: "#{mime}: #{ext}",
            count: arr.length,
            files: arr
          }
        )
      end
    end
    objmap_ext_status.each_key do |mime|
      objmap_ext_status[mime].each do |ext, stat|
        ohobj.analysis.append_key(
          :mime_ext_status,
          {
            mime: mime,
            ext: ext,
            status: stat
          }
        )
      end
    end

    ohobj
  end
end
