# frozen_string_literal: true

require 'json'
require_relative 'oh_tasktest'

# Merritt Object Health test that evaluates the state of an object based on the results of
# the analysis tasks performed on the object's files
class ClassificationTest < ObjHealthTest
  def initialize(objh, taskdef, name)
    super
    @mapping = ObjectHealthMatch.make_status_key_map(taskdef, :status_keys)
  end

  def object_hash_key
    :na_classification
  end

  def run_test(ohobj)
    @mapping.fetch(ohobj.analysis.hash_object.fetch(object_hash_key, :na).to_sym, :FAIL)
  end
end

# Merritt Object Health test that evaluates an object's content files classification
class ObjectClassificationTest < ClassificationTest
  def object_hash_key
    :object_classification
  end
end

# Merritt Object Health test that evaluates an object's metadata files classification
class MetadataClassificationTest < ClassificationTest
  def object_hash_key
    :metadata_classification
  end
end
