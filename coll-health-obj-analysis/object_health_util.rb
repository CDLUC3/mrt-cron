require 'json'
require 'json-schema'
require 'yaml'
require 'uc3-ssm'
require_relative 'schema_exception'

class ObjectHealthUtil
  def self.yaml_schema
    'config/yaml_schema.yml'
  end

  def self.obj_schema
    'config/obj_schema.yml'
  end

  def self.json_schema_schema
    JSON::Validator.validator_for_name("draft6").metaschema
  end

  def self.get_ssm_config(file)
    config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: file)
    JSON.parse(config.to_json, symbolize_names: true)
  end

  def self.get_config(file)
    config = YAML.load(File.read(file))
    JSON.parse(config.to_json, symbolize_names: true)
  end

  def self.get_schema(file)
    config = YAML.load(File.read(file))
    schema = JSON.parse(config.to_json)
    schema
  end

  def self.validate_schema_file(filename)
    self.validate_schema(get_schema(filename), filename)
  end

  def self.get_and_validate_schema_file(filename)
    file = get_schema(filename)
    self.validate_schema(file, filename)
    file
  end

  def self.validate_schema(file, label)
    self.validate(ObjectHealthUtil.json_schema_schema, file, label)
  end

  def self.validate(schema, obj, label)
    val = JSON::Validator.fully_validate(schema, obj)
    unless val.empty?
      puts "\n** Schema Validation Failure for #{label}"
      val.each do |s|
        puts " - #{s}"
      end
      raise MySchemaException.new "Yaml invalid for schema"
    end 
    true
  end

  def self.status_values
    [:SKIP, :PASS, :INFO, :WARN, :FAIL]
  end

  def self.status_val(status)
    self.status_values.each_with_index do |v,i|
      return i if v == status
    end
    0
  end

  def self.compare_state(ostate, status)
    ObjectHealthUtil.status_val(ostate) < ObjectHealthUtil.status_val(status) ? status : ostate
  end

end