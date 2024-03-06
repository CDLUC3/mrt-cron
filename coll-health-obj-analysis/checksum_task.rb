# frozen_string_literal: true

require 'json'
require 'mustache'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class ChecksumTask < ObjHealthTask
  def run_task(ohobj)
    digests = {}
    ohobj.build.hash_object.fetch(:producer, {}).each do |v|
      dig = v[:digest_value]
      digests[dig] = digests.fetch(dig, []).append(v[:pathname])
    end
    ohobj.analysis.set_key(:duplicate_checksums_within_object, [])
    digests.each do |dig, arr|
      next if arr.length <= 1
      ohobj.analysis.append_key(:duplicate_checksums_within_object, {digest: dig, count: arr.length, paths: arr})
    end
    ohobj
  end
end
