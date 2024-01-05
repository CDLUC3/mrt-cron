# JSON/Yaml Schema Validation

_To view this presentation as a slideshow_
```
docker-compose -f sample/docker-compose.yml up --build
```

---

# JSON Schema Resources

https://json-schema.org/overview/what-is-jsonschema

---

# Merritt Object Analysis as JSON Objects

----

## Sample JSON Object

- [Merritt Object Analysis](https://github.com/CDLUC3/mrt-cron/blob/main/coll-health-obj-analysis/sample/objects_details.json)

----

```json
{
  "id": 1741491,
  "@timestamp": "2023-12-19T11:50:09-0800",
  "build": {
    "id": 1741491,
    "identifiers": {
      "ark": "ark:/99999/fk4348tn0h",
      "localids": [

      ]
    },
    ...
  },
  "analysis":{}
  "tests": {}
}
```

----

## JSON Schema for the object

- [Merritt Object Analysis Schema](https://github.com/CDLUC3/mrt-cron/blob/main/coll-health-obj-analysis/config/obj_schema.json)

----

```json
{
  "$id": "https://merritt.cdlib.org/obj_schema.yml",
  "title": "Merritt Object Health Object Schema",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "@timestamp",
    "build"
  ],
  "properties": {
    "id": {
      "type": "number"
    },
    "@timestamp": {
      "type": "string"
    },
    "build": {
      "type": "object",
      "additionalProperties": false,
      "properties": {}
    }
    "analysis":{}
    "tests": {}
  }
}

```

----

## Code to invoke schema validation

```rb
require 'json'
require 'json-schema'
require 'yaml'

obj = JSON.parse(File.read("sample/objects_details.json"))
schema = JSON.parse(File.read("config/obj_schema.json"))
stat = JSON::Validator.fully_validate(schema, obj)
puts "valid" if stat.empty?
puts stat unless stat.empty?
```

Output
```
valid
```

----

## Sample JSON Object with validity issues

- [Merritt Object Analysis - Invalid object](https://github.com/CDLUC3/mrt-cron/blob/main/coll-health-obj-analysis/sample/objects_details.bad.json)

----

```json [5-6]
{
  "id": 1741491,
  "@timestamp": "2023-12-19T11:50:09-0800",
  "build": {
    "foo": "bar",
    "id": "1741491",
    "identifiers": {
      "ark": "ark:/99999/fk4348tn0h",
      "localids": [

      ]
    },
    ...
  }
}
```
"foo" is not in schema.  "id" is defined as numeric.

----

## Code to invoke schema validation

```rb
obj = JSON.parse(File.read("sample/objects_details.bad.json"))
schema = JSON.parse(File.read("config/obj_schema.json"))
stat = JSON::Validator.fully_validate(schema, obj)
puts "valid" if stat.empty?
puts stat unless stat.empty?
```

----

Output
```
The property '#/build' contains additional properties ["foo"] outside of the schema when none are allowed in schema 1fcf2501-c004-574f-a4af-5f6791ccef0f
The property '#/build/id' of type string did not match the following type: number in schema 1fcf2501-c004-574f-a4af-5f6791ccef0f
```

----

## VSCode Configuration to enable validation
_Uses Prettify JSON v0.0.3 extension_

```yml
    "json.schemas": [
        {
            "fileMatch": [
                "objects_details.*.json"
            ],
            "url": "./coll-health-obj-analysis/config/obj_schema.json"
        }
```

----

## Validate our JSON Schema against the JSON Schema Schema

```rb
schema_for_schema = JSON::Validator.validator_for_name('draft6').metaschema
stat = JSON::Validator.fully_validate(schema_for_schema, schema)
puts "valid" if stat.empty?
puts stat unless stat.empty?
```

Output
```
valid
```

----

## Take a closer look at our schema... 
_Compliant JSON files can be difficult to maintain by hand in an editor..._

- [Merritt Object Analysis Schema](https://github.com/CDLUC3/mrt-cron/blob/main/coll-health-obj-analysis/config/obj_schema.json)

----

JSON files can be written as YAML which is often easier to maintain.

- [Merritt Object Analysis Schema - YAML format](https://github.com/CDLUC3/mrt-cron/blob/main/coll-health-obj-analysis/config/obj_schema.yml)

----

```yml
"$id": https://merritt.cdlib.org/obj_schema.yml
title: Merritt Object Health Object Schema
type: object
additionalProperties: false
required:
- id
- "@timestamp"
- build
properties:
  id: 
    type: number
  "@timestamp":
    type: string
  build:
    type: object
    additionalProperties: false
    properties: 
      ...
  analysis:
    ...
  tests:
    ...
```

----

## VSCode configuration to validate schema YAML
_Uses YAML v1.14.0 extension_

```yml
    "yaml.schemas": {
        "./coll-health-obj-analysis/vendor/bundle/ruby/3.0.0/gems/json-schema-4.1.1/resources/draft-06.json": [
            "*_schema.yml"
        ]
    },
```

----

## Conversion program to turn YAML into JSON
```rb
File.open('config/obj_schema.json', 'w') do |f|  f.write(
    JSON.pretty_generate(
      YAML.safe_load(
        File.read('config/obj_schema.yml'), 
        aliases: true
      )
    )
  )
end
```

---

# Rules engine driven from a complex Yaml file

----

## Validating Yaml Config File
- [Complex Yaml Config File](https://github.com/CDLUC3/mrt-cron/blob/main/coll-health-obj-analysis/config/merritt_classifications.yml)

----

## Schema for the Config file
- [Complex Yaml Config File Schema](https://github.com/CDLUC3/mrt-cron/blob/main/coll-health-obj-analysis/config/yaml_schema.yml)

----

## VSCode configuration for editing the Yaml file

```yml
    "json.schemas": [
        {
            "fileMatch": [
                "merritt_classifications.yml"
            ],
            "url": "./coll-health-obj-analysis/config/yaml_schema.json"
        }
    ],
    "yaml.schemas": {
        "./coll-health-obj-analysis/config/yaml_schema.json": [
            "merritt_classifications.yml"
        ],
    },
```

----

## Code to Validate the Yaml config file using a Yaml formatted JSON schema
```rb
yaml_schema = JSON.parse(
  YAML.safe_load(File.read('config/yaml_schema.yml'), aliases: true).to_json
)
config = JSON.parse(
  YAML.safe_load(File.read('config/merritt_classifications.yml'),  aliases: true).to_json
)
stat = JSON::Validator.fully_validate(schema_for_schema, schema)
puts "valid" if stat.empty?
puts stat unless stat.empty?
```

----

Output
```
valid
```

----

## Code to validate the Yaml formatted JSON schema
```rb
schema_for_schema = JSON::Validator.validator_for_name('draft6').metaschema
yaml_schema = JSON.parse(
  YAML.safe_load(File.read('config/yaml_schema.yml'), aliases: true).to_json
)
stat = JSON::Validator.fully_validate(schema_for_schema, yaml_schema)
puts "valid" if stat.empty?
puts stat unless stat.empty?
```

Output
```
valid
```

---

# Why are we doing this?
- [Project Goals](https://github.com/CDLUC3/mrt-cron/tree/main/coll-health-obj-analysis#merritt-collection-health-analysis-and-reporting)
- [Object Analysis Data Model](https://github.com/CDLUC3/mrt-cron/blob/main/coll-health-obj-analysis/data_model.md)