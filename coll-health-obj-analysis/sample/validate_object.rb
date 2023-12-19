# frozen_string_literal: true

require 'json'
require 'json-schema'
require 'yaml'

obj = JSON.parse(File.read('sample/objects_details.json'))
schema = JSON.parse(File.read('config/obj_schema.json'))
stat = JSON::Validator.fully_validate(schema, obj)
puts 'valid' if stat.empty?
puts stat unless stat.empty?

obj = JSON.parse(File.read('sample/objects_details.bad.json'))
stat = JSON::Validator.fully_validate(schema, obj)
puts 'valid' if stat.empty?
puts stat unless stat.empty?

schema_for_schema = JSON::Validator.validator_for_name('draft6').metaschema
stat = JSON::Validator.fully_validate(schema_for_schema, schema)
puts 'valid' if stat.empty?
puts stat unless stat.empty?

yaml_schema = JSON.parse(YAML.safe_load(File.read('config/yaml_schema.yml'), aliases: true).to_json)
config = JSON.parse(YAML.safe_load(File.read('config/merritt_classifications.yml'), aliases: true).to_json)
stat = JSON::Validator.fully_validate(yaml_schema, config)
puts 'valid' if stat.empty?
puts stat unless stat.empty?

schema_for_schema = JSON::Validator.validator_for_name('draft6').metaschema
yaml_schema = JSON.parse(YAML.safe_load(File.read('config/yaml_schema.yml'), aliases: true).to_json)
stat = JSON::Validator.fully_validate(schema_for_schema, yaml_schema)
puts 'valid' if stat.empty?
puts stat unless stat.empty?
