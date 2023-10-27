require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class ObjectClassificationTest < ObjHealthTest
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
    @mapping = {}
    @taskdef.fetch(:categorize, {}).each do |k,list|
      list.each do |v|
        @mapping[v.to_sym] = k
      end
    end
  end

  def run_test(ohobj)
    @mapping.fetch(ohobj.analysis.get_object.fetch(:object_classification, :na).to_sym, :FAIL)
  end
end