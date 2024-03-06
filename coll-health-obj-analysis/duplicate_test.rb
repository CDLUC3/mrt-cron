# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class DuplicateChecksumTest < ObjHealthTest
  def run_test(ohobj)
    ohobj.analysis.hash_object.fetch(:duplicate_checksums_within_object, []).empty? ? :PASS : report_status
  end
end
