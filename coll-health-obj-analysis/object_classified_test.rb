# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'

# write analysis->mime->[status]->mime->[mime-type]
class ClassificationTest < ObjHealthTest
  def initialize(objh, taskdef, name)
    super(objh, taskdef, name)
    @mapping = ObjectHealthMatch.make_status_key_map(taskdef, :status_keys)
  end

  def object_hash_key
    :na_classification
  end

  def run_test(ohobj)
    @mapping.fetch(ohobj.analysis.hash_object.fetch(object_hash_key, :na).to_sym, :FAIL)
  end
end

class ObjectClassificationTest < ClassificationTest
  def object_hash_key
    :object_classification
  end
end

class MetadataClassificationTest < ClassificationTest
  def object_hash_key
    :metadata_classification
  end
end
