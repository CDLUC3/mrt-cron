require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class ClassificationTest < ObjHealthTest
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
    @mapping = ObjectHealthMatch.make_status_key_map(taskdef, :status_keys)
  end

  def get_key
    :na_classification
  end

  def run_test(ohobj)
    @mapping.fetch(ohobj.analysis.get_object.fetch(get_key, :na).to_sym, :FAIL)
  end
end

class ObjectClassificationTest < ClassificationTest
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def get_key
    :object_classification
  end
end

class MetadataClassificationTest < ClassificationTest
  def initialize(oh, taskdef, name)
    super(oh, taskdef, name)
  end

  def get_key
    :metadata_classification
  end
end