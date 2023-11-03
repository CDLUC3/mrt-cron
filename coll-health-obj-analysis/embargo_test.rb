require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class EmbargoTest < ObjHealthTest
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def run_test(ohobj)
    status = :PASS
    if !ohobj.build.get_object.fetch(:embargo_end_date, "").empty?
      status = report_status
    end
    status
  end
end