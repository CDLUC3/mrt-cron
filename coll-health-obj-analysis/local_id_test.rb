# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class LocalIdTest < ObjHealthTest
  def run_test(ohobj)
    status = :PASS
    status = report_status if ohobj.build.hash_object.fetch(:identifiers, {}).fetch(:localids, []).empty?
    status
  end
end
