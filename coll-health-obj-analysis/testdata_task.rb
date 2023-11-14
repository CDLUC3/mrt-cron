require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class IdentifyTestDataTask < ObjHealthTask
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def run_task(ohobj)
    rx = %r[^\d\d\d\d_\d\d_(v1file|combo)$]
    ohobj.analysis.set_key(:merritt_test_data, true)
    ohobj
  end
end