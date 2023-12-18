# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class IdentifyTestDataTask < ObjHealthTask
  def run_task(ohobj)
    ohobj.analysis.set_key(:merritt_test_data, false)
    ohobj.build.hash_object.fetch(:identifiers, {}).fetch(:localids, []).each do |lid|
      ohobj.analysis.set_key(:merritt_test_data, true) if lid =~ /^\d\d\d\d_\d\d_\d\d_\d\d\d\d_(v1file|combo)$/
    end
    ohobj
  end
end
