# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class EmptyTest < ObjHealthTest
  def run_test(ohobj)
    status = :PASS
    if ohobj.build.get_object.fetch(:file_counts, {}).fetch(:empty, 0).positive?
      status = report_status
      ohobj.build.get_object.fetch(:producer, {}).each do |v|
        status = report_status(cond: :producer) if v.fetch(:empty, false)
      end
    end
    status
  end
end
