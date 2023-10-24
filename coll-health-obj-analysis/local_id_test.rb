require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class LocalIdTest < ObjHealthTest
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def run_test(ohobj)
    status = :PASS
    if ohobj.build.get_object.fetch(:identifiers, {}).fetch(:localids, []).empty?
      status = :WARN
    end
    status
  end
end