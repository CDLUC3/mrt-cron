require 'spec_helper'
require_relative '../object_health_util'
require_relative '../object_health'

RSpec.describe 'object health tests' do
  it "Validate the Merritt Classification Schema" do
    ObjectHealthUtil.validate_schema_file(ObjectHealthUtil.yaml_schema)
  end

  it "Identify Issue in Merritt Classification Schema" do
    expect {
      schema = ObjectHealthUtil.get_schema(ObjectHealthUtil.yaml_schema)
      # corrupt the schema object
      schema["type"] = "foo"
      ObjectHealthUtil.validate_schema(schema, ObjectHealthUtil.yaml_schema)  
    }.to raise_error(MySchemaException)
  end

  it "Validate the Object Health Schema" do
    ObjectHealthUtil.validate_schema_file(ObjectHealthUtil.obj_schema)
  end

  it "Identify Issue in Object Health Object Schema" do
    expect {
      schema = ObjectHealthUtil.get_schema(ObjectHealthUtil.obj_schema)
      # corrupt the schema object
      schema["required"].append(22)
      ObjectHealthUtil.validate_schema(schema, ObjectHealthUtil.obj_schema)  
    }.to raise_error(MySchemaException)
  end

  it "Test Object Health Usage Exit" do
    expect {
      oh = ObjectHealth.new(['--help'])
    }.to raise_error(SystemExit)
  end

  it "Test Object Health Usage" do
    expect {
      begin
        oh = ObjectHealth.new(['--help'])
      rescue SystemExit
      end
    }.to output(%r[Usage:]).to_stdout
  end

  it "Test Object Health Usage in spite of bad credentials" do
    expect {
      oh = ObjectHealth.new(['--help'], cfos: 'spec/config/opensearch_bad_cred.ssm.yml')
      oh.get_object_list  
    }.to raise_error(SystemExit)
  end

  it "Test Object Health Construction ... verify database and opensearch connection" do
    oh = ObjectHealth.new([])
    oh.get_object_list
  end

  it "Test Object Health Construction - invalid opensearch credentials" do
    expect {
      oh = ObjectHealth.new([], cfos: 'spec/config/opensearch_bad_cred.ssm.yml')
    }.to raise_error(OpenSearch::Transport::Transport::Errors::Unauthorized)
  end

  it "Test Object Health Construction - invalid opensearch host" do
    expect {
      oh = ObjectHealth.new([], cfos: 'spec/config/opensearch_bad_host.ssm.yml')
    }.to raise_error(Faraday::ConnectionFailed)
  end

  it "Test Object Health Construction - invalid db credentials" do
    expect {
      oh = ObjectHealth.new([], cfdb: 'spec/config/database_bad_cred.ssm.yml')
      oh.get_object_list
    }.to raise_error(Mysql2::Error::ConnectionError)
  end

  it "Test Object Health Construction - invalid db host" do
    expect {
      oh = ObjectHealth.new([], cfdb: 'spec/config/database_bad_host.ssm.yml')
      oh.get_object_list
    }.to raise_error(Mysql2::Error::ConnectionError)
  end

  it "Test schema validation failure" do
    expect {
      oh = ObjectHealth.new([], cfmc: 'spec/config/empty.yml')
      oh.get_object_list
    }.to raise_error(MySchemaException)
  end
  
end