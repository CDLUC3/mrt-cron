#! /bin/sh
bundle exec ruby << HERE
require 'yaml'
require 'json'
File.open('config/yaml_schema.json', 'w') do |f|
  f.write(JSON.pretty_generate(YAML.safe_load(File.read('config/yaml_schema.yml'), aliases: true)))
end
File.open('config/obj_schema.json', 'w') do |f|
  f.write(JSON.pretty_generate(YAML.safe_load(File.read('config/obj_schema.yml'), aliases: true)))
end
HERE