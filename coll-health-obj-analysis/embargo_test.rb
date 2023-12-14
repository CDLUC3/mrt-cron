# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class EmbargoTest < ObjHealthTest
  def run_test(ohobj)
    status = :PASS
    status = report_status unless ohobj.build.get_object.fetch(:embargo_end_date, '').empty?
    status
  end
end
