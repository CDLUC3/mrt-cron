require 'spec_helper'
require 'logger'
require_relative '../object_health_util'
require_relative '../object_health'

RSpec.describe 'object health tests' do
  def ssm_override(map)
    allow_any_instance_of(Logger).to receive(:debug).with(anything)
    allow_any_instance_of(Uc3Ssm::ConfigResolver).to receive(:lookup_ssm).and_wrap_original do |method, arg|
      if map.key?(arg.to_sym)
        method.call('__na__', map[arg.to_sym])
      else
        method.call(arg)
      end
    end
  end

  describe "Validate JSON/Yaml Schema Files" do
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

    it "Test Yaml schema validation failure" do
      expect {
        oh = ObjectHealth.new([], cfmc: 'spec/config/empty.yml')
        oh.get_object_list
      }.to raise_error(MySchemaException)
    end
  
  end

  describe "Test command line options" do
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

    describe "Configure validation OFF" do
      before(:each) do
        @cfmc = ObjectHealthUtil.get_config(ObjectHealthUtil.merritt_classifications)
        @cfmc[:runtime][:validation] = false
      end

      it "Verify validation OFF" do
        oh = ObjectHealth.new([], cfmc: @cfmc)
        expect(oh.validation).to be false
      end

      it "Verify validation on from command line" do
        oh = ObjectHealth.new(["--validation"], cfmc: @cfmc)
        expect(oh.validation).to be true
      end
    end

    describe "Configure validation ON" do
      before(:each) do
        @cfmc = ObjectHealthUtil.get_config(ObjectHealthUtil.merritt_classifications)
        @cfmc[:runtime][:validation] = true
      end

      it "Verify validation ON" do
        oh = ObjectHealth.new([], cfmc: @cfmc)
        expect(oh.validation).to be true
      end

      it "Verify validation off from command line" do
        oh = ObjectHealth.new(["--no-validation"], cfmc: @cfmc)
        expect(oh.validation).to be false
      end
    end
  end

  describe "Test credential handling" do
    it "Test Object Health Construction ... verify database and opensearch connection" do
      oh = ObjectHealth.new([])
      oh.get_object_list
    end

    it "Test Object Health Usage in spite of bad credentials" do
      expect {
        ssm_override({'billing/readwrite/db-user': 'foo'})
        oh = ObjectHealth.new(['--help'])
        oh.get_object_list  
      }.to raise_error(SystemExit)
    end
  
    it "Test Object Health Construction with bad db hostname" do
      expect {
        ssm_override({'billing/db-host': 'bad-host.cdlib.org'})
        oh = ObjectHealth.new([])
        oh.get_object_list
      }.to raise_error(Mysql2::Error::ConnectionError)
    end
  
    it "Test Object Health Construction with bad db credential" do
      expect {
        ssm_override({'billing/readwrite/db-user': 'foo'})
        oh = ObjectHealth.new([])
        oh.get_object_list
      }.to raise_error(Mysql2::Error::ConnectionError)
    end
  
    it "Test Object Health Construction - invalid opensearch credentials" do
      expect {
        ssm_override({'objhealth/opensearch_user': 'foo'})
        oh = ObjectHealth.new([])
      }.to raise_error(OpenSearch::Transport::Transport::Errors::Unauthorized)
    end
  
    it "Test Object Health Construction - invalid opensearch host" do
      expect {
        ssm_override({'objhealth/opensearch_host': 'bad-host.cdlib.org'})
        oh = ObjectHealth.new([])
      }.to raise_error(Faraday::ConnectionFailed)
    end
  end
  
end