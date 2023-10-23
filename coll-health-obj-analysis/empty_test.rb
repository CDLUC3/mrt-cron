require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class EmptyTest < ObjHealthTest
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def run_test(ohobj)
    status = :PASS
    if ohobj.build.get_object.fetch(:empty, 0) > 0
      status = :INFO
      ohobj.build.producer.each do |v|
        status = WARN if v.fetch(:deleted, false)
      end
    end
    status
  end
end