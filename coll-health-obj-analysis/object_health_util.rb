# frozen_string_literal: true

require 'json'
require 'json-schema'
require 'yaml'
require 'uc3-ssm'
require_relative 'schema_exception'

# Utility interface to external tools for Yaml parsing, SSM resolution and JSON schema validation
class ObjectHealthUtil
  def self.yaml_schema
    'config/yaml_schema.yml'
  end

  def self.obj_schema
    'config/obj_schema.yml'
  end

  def self.merritt_classifications
    'config/merritt_classifications.yml'
  end

  def self.json_schema_schema
    JSON::Validator.validator_for_name('draft6').metaschema
  end

  def self.ssm_config(file)
    config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: file)
    JSON.parse(config.to_json, symbolize_names: true)
  end

  def self.config_from_yaml(file)
    config = YAML.safe_load(File.read(file), aliases: true)
    JSON.parse(config.to_json, symbolize_names: true)
  end

  def self.json_schema(file)
    config = YAML.safe_load(File.read(file), aliases: true)
    JSON.parse(config.to_json)
  end

  def self.validate_schema_file(filename, verbose: true)
    validate_schema(json_schema(filename), filename, verbose: verbose)
  end

  def self.read_and_validate_schema_file(filename, verbose: true)
    file = json_schema(filename)
    validate_schema(file, filename, verbose: verbose)
    file
  end

  def self.validate_schema(file, label, verbose: true)
    validate(ObjectHealthUtil.json_schema_schema, file, label, verbose: verbose)
  end

  def self.validate(schema, obj, label, verbose: true)
    val = JSON::Validator.fully_validate(schema, obj)
    unless val.empty?
      ex = MySchemaException.new(val)
      ex.print(label) if verbose
      raise ex
    end
    true
  end

  def self.status_values
    %i[SKIP PASS INFO WARN FAIL]
  end

  def self.status_val(status)
    status_values.each_with_index do |v, i|
      return i if v == status
    end
    0
  end

  def self.compare_state(ostate, status)
    ObjectHealthUtil.status_val(ostate) < ObjectHealthUtil.status_val(status) ? status : ostate
  end

  def self.num_format(num)
    return '' if num.nil?

    num.to_s.chars.to_a.reverse.each_slice(3).map(&:join).join(',').reverse
  end
end
