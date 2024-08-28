# frozen_string_literal: true

require 'json'
require 'json-schema'
require 'yaml'

@val_errors = {}

def validate(schema, doc, label)
  stat = JSON::Validator.fully_validate(schema, doc)
  return if stat.empty?

  @val_errors[label] = stat
  puts "Validation errors for #{label}"
  stat.each do |s|
    puts "- #{s}"
  end
  puts
end

schema_for_schema = JSON::Validator.validator_for_name('draft6').metaschema

obj_schema = JSON.parse(File.read('config/obj_schema.json'))
validate(schema_for_schema, obj_schema, 'Validate Object Schema')

yaml_schema = JSON.parse(YAML.safe_load_file('config/yaml_schema.yml', aliases: true).to_json)
validate(schema_for_schema, yaml_schema, 'Validate Yaml Schema')

config = JSON.parse(YAML.safe_load_file('config/merritt_classifications.yml', aliases: true).to_json)
validate(yaml_schema, config, 'Validate merritt_classifications.yml')

exit 1 unless @val_errors.empty?
