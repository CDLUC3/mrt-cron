require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class DeletedTest < ObjHealthTest
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def run_test(ohobj)
    ohobj.build.get_object.fetch(:file_counts, {}).fetch(:deleted, 0) > 0 ? report_status : :PASS
  end
end