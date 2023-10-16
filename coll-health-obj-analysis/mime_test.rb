require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class MimeTest < ObjHealthTest
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def run_test(ohobj)
    status = :SKIP
    m = ohobj.get_analysis.fetch(:mimes, {})
    ObjectHealth.status_values.each do |stat|
      status = stat if m.fetch(stat, []).length > 0
    end
    status
  end
end