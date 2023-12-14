# frozen_string_literal: true

require 'spec_helper'
require 'logger'
require_relative '../object_health_util'
require_relative '../object_health'

RSpec.describe 'object health tests' do
  before(:each) do
    ENV['OBJHEALTH_SILENT'] = 'Y'
  end
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

  describe 'Validate JSON/Yaml Schema Files' do
    it 'Validate the Merritt Classification Schema' do
      ObjectHealthUtil.validate_schema_file(ObjectHealthUtil.yaml_schema, verbose: false)
    end

    it 'Identify Issue in Merritt Classification Schema' do
      expect do
        schema = ObjectHealthUtil.get_schema(ObjectHealthUtil.yaml_schema)
        # corrupt the schema object
        schema['type'] = 'foo'
        ObjectHealthUtil.validate_schema(schema, ObjectHealthUtil.yaml_schema, verbose: false)
      end.to raise_error(MySchemaException)
    end

    it 'Validate the Object Health Schema' do
      ObjectHealthUtil.validate_schema_file(ObjectHealthUtil.obj_schema, verbose: false)
    end

    it 'Identify Issue in Object Health Object Schema' do
      expect do
        schema = ObjectHealthUtil.get_schema(ObjectHealthUtil.obj_schema)
        # corrupt the schema object
        schema['required'].append(22)
        ObjectHealthUtil.validate_schema(schema, ObjectHealthUtil.obj_schema, verbose: false)
      end.to raise_error(MySchemaException)
    end

    it 'Test Yaml schema validation failure' do
      expect do
        oh = ObjectHealth.new(cfmc: 'spec/config/empty.yml')
        oh.get_object_list
      end.to raise_error(MySchemaException)
    end
  end

  describe 'Test command line options' do
    describe 'Usage test' do
      it 'Test Object Health Usage Exit' do
        allow($stdout).to receive(:write)
        expect do
          oh = ObjectHealth.new(['--help'])
        end.to raise_error(SystemExit)
      end

      it 'Test Object Health Usage' do
        expect do
          oh = ObjectHealth.new(['--help'])
        rescue SystemExit
        end.to output(/Usage:/).to_stdout
      end
    end

    describe 'Build, Analyze, Test Options' do
      before(:each) do
        @action_invoked = {}
        allow_any_instance_of(ObjectHealth).to receive(:export_object).and_wrap_original do |_method, _arg|
          inc(:export_object)
        end
        allow_any_instance_of(ObjectHealthDb).to receive(:update_object_build).and_wrap_original do |_method, _arg|
          inc(:update_object_build)
        end
        allow_any_instance_of(ObjectHealthDb).to receive(:update_object_analysis).and_wrap_original do |_method, _arg|
          inc(:update_object_analysis)
        end
        allow_any_instance_of(ObjectHealthDb).to receive(:update_object_tests).and_wrap_original do |_method, _arg|
          inc(:update_object_tests)
        end

        allow_any_instance_of(ObjectHealthDb).to receive(:clear_object_health).with(:build).and_wrap_original do |_method, _arg|
          inc(:clear_object_build)
        end
        allow_any_instance_of(ObjectHealthDb).to receive(:clear_object_health).with(:analysis).and_wrap_original do |_method, _arg|
          inc(:clear_object_analysis)
        end
        allow_any_instance_of(ObjectHealthDb).to receive(:clear_object_health).with(:tests).and_wrap_original do |_method, _arg|
          inc(:clear_object_tests)
        end
      end

      def inc(key)
        @action_invoked[key] = @action_invoked.fetch(key, 0) + 1
      end

      def verify_invocations(export_stat, build_stat, analysis_stat, tests_stat)
        expect(@action_invoked.fetch(:export_object, 0) > 0).to be export_stat
        expect(@action_invoked.fetch(:update_object_build, 0) > 0).to be build_stat
        expect(@action_invoked.fetch(:update_object_analysis, 0) > 0).to be analysis_stat
        expect(@action_invoked.fetch(:update_object_tests, 0) > 0).to be tests_stat
      end

      def verify_invocations_counts(export_count, build_count, analysis_count, tests_count)
        expect(@action_invoked.fetch(:export_object, 0)).to eq(export_count)
        expect(@action_invoked.fetch(:update_object_build, 0)).to eq(build_count)
        expect(@action_invoked.fetch(:update_object_analysis, 0)).to eq(analysis_count)
        expect(@action_invoked.fetch(:update_object_tests, 0)).to eq(tests_count)
      end

      def verify_clear_counts(build_count, analysis_count, tests_count)
        expect(@action_invoked.fetch(:clear_object_build, 0)).to eq(build_count)
        expect(@action_invoked.fetch(:clear_object_analysis, 0)).to eq(analysis_count)
        expect(@action_invoked.fetch(:clear_object_tests, 0)).to eq(tests_count)
      end

      it 'test no options' do
        oh = ObjectHealth.new(['--id=184856', '--no-validation'])
        expect(oh.options.fetch(:build_objects, false)).to be false
        expect(oh.options.fetch(:analyze_objects, false)).to be false
        expect(oh.options.fetch(:test_objects, false)).to be false

        oh.preliminary_tasks
        oh.process_objects

        verify_invocations(false, false, false, false)
      end

      it 'test build option' do
        oh = ObjectHealth.new(['-b', '--id=184856', '--no-validation'])
        expect(oh.options.fetch(:build_objects, false)).to be true
        expect(oh.options.fetch(:analyze_objects, false)).to be false
        expect(oh.options.fetch(:test_objects, false)).to be false

        oh.preliminary_tasks
        oh.process_objects

        verify_invocations(true, true, false, false)
      end

      it 'test build option - id query' do
        oh = ObjectHealth.new(['-b', '--id=184856', '--no-validation'])

        oh.preliminary_tasks
        oh.process_objects

        expect(oh.get_queries.first).to match(/and o.id = '184856'/)
        verify_invocations_counts(1, 1, 0, 0)
      end

      it 'test build option - default collection' do
        oh = ObjectHealth.new(['-b', '--limit=3', '--no-validation'])

        oh.preliminary_tasks
        oh.process_objects

        expect(oh.get_queries.first).to match(/merritt_demo/)
        verify_invocations_counts(3, 3, 0, 0)
      end

      it 'test build option - default collection - loop 4 times' do
        oh = ObjectHealth.new(['-b', '--limit=3', '--loop=4', '--no-validation'])

        oh.preliminary_tasks
        oh.process_objects

        expect(oh.get_queries.first).to match(/merritt_demo/)
        verify_invocations_counts(12, 12, 0, 0)
      end

      it 'test build option - custom collection collection' do
        oh = ObjectHealth.new(['-b', '--limit=3', '--mnemonic=escholarship', '--no-validation'])

        oh.preliminary_tasks
        oh.process_objects

        expect(oh.get_queries.first).to match(/escholarship/)
        verify_invocations_counts(3, 3, 0, 0)
      end

      it 'test build option - custom query' do
        oh = ObjectHealth.new(['-b', '--limit=3', '--query=has-build', '--no-validation'])

        oh.preliminary_tasks
        oh.process_objects

        expect(oh.get_queries.first).to match(/where h.inv_object_id = o.id/)
        # counts will depend on the state of the database
        # verify_invocations_counts(0, 0, 0, 0)
      end

      it 'test build option - use tag to pull etd collections for all 10 campuses' do
        oh = ObjectHealth.new(['-b', '--limit=3', '--tag=tag_etd', '--no-validation'])

        oh.preliminary_tasks
        oh.process_objects

        expect(oh.get_queries.length).to eq(10)
        verify_invocations_counts(30, 30, 0, 0)
      end

      it 'test build option - long form' do
        oh = ObjectHealth.new(['--build', '--id=184856', '--no-validation'])
        expect(oh.options.fetch(:build_objects, false)).to be true
        expect(oh.options.fetch(:analyze_objects, false)).to be false
        expect(oh.options.fetch(:test_objects, false)).to be false

        oh.preliminary_tasks
        oh.process_objects

        verify_invocations(true, true, false, false)
      end

      it 'test analyze option' do
        oh = ObjectHealth.new(['-a', '--id=184856', '--no-validation'])
        expect(oh.options.fetch(:build_objects, false)).to be false
        expect(oh.options.fetch(:analyze_objects, false)).to be true
        expect(oh.options.fetch(:test_objects, false)).to be false

        oh.preliminary_tasks
        oh.process_objects

        verify_invocations(true, false, true, false)
      end

      it 'test analyze option - long form' do
        oh = ObjectHealth.new(['--analyze', '--id=184856', '--no-validation'])
        expect(oh.options.fetch(:build_objects, false)).to be false
        expect(oh.options.fetch(:analyze_objects, false)).to be true
        expect(oh.options.fetch(:test_objects, false)).to be false

        oh.preliminary_tasks
        oh.process_objects

        verify_invocations(true, false, true, false)
      end

      it 'test run tests option' do
        oh = ObjectHealth.new(['-t', '--id=184856', '--no-validation'])
        expect(oh.options.fetch(:build_objects, false)).to be false
        expect(oh.options.fetch(:analyze_objects, false)).to be false
        expect(oh.options.fetch(:test_objects, false)).to be true

        oh.preliminary_tasks
        oh.process_objects

        verify_invocations(true, false, false, true)
      end

      it 'test run tests option - long form' do
        oh = ObjectHealth.new(['--test', '--id=184856', '--no-validation'])
        expect(oh.options.fetch(:build_objects, false)).to be false
        expect(oh.options.fetch(:analyze_objects, false)).to be false
        expect(oh.options.fetch(:test_objects, false)).to be true

        oh.preliminary_tasks
        oh.process_objects

        verify_invocations(true, false, false, true)
      end

      it 'test all stages' do
        oh = ObjectHealth.new(['-bat', '--id=184856', '--no-validation'])
        expect(oh.options.fetch(:build_objects, false)).to be true
        expect(oh.options.fetch(:analyze_objects, false)).to be true
        expect(oh.options.fetch(:test_objects, false)).to be true

        oh.preliminary_tasks
        oh.process_objects

        verify_invocations(true, true, true, true)
      end

      it 'test all stages and validate json' do
        oh = ObjectHealth.new(['-bat', '--id=184856', '--validation'])
        expect(oh.options.fetch(:build_objects, false)).to be true
        expect(oh.options.fetch(:analyze_objects, false)).to be true
        expect(oh.options.fetch(:test_objects, false)).to be true

        expect(ObjectHealthUtil).to receive(:validate)

        oh.preliminary_tasks
        oh.process_objects

        verify_invocations(true, true, true, true)
      end

      it 'test all stages with limit' do
        oh = ObjectHealth.new(['-bat', '--limit=3', '--validation'])
        expect(oh.options.fetch(:build_objects, false)).to be true
        expect(oh.options.fetch(:analyze_objects, false)).to be true
        expect(oh.options.fetch(:test_objects, false)).to be true

        oh.preliminary_tasks
        oh.process_objects

        verify_invocations_counts(3, 3, 3, 3)
      end

      it 'test --clear-build using a supplied query, exit due to items awaiting rebuild' do
        allow_any_instance_of(ObjectHealthDb).to receive(:object_health_status).and_return({
                                                                                             awaiting_rebuild: 1
                                                                                           })
        oh = ObjectHealth.new(['-bat', '--limit=3', '--query=has-build', '--clear-build'])

        expect do
          oh.preliminary_tasks
          oh.process_objects
        end.to raise_error(SystemExit)
      end

      it 'test --clear-build using a supplied query (--force-rebuild specified)' do
        allow_any_instance_of(ObjectHealthDb).to receive(:object_health_status).and_return({
                                                                                             awaiting_rebuild: 1
                                                                                           })
        oh = ObjectHealth.new(['-bat', '--limit=3', '--query=has-build', '--clear-build', '--force-rebuild'])

        oh.preliminary_tasks
        oh.process_objects

        verify_clear_counts(1, 0, 0)
        expect(oh.get_clear_query).to eq('')
      end

      it 'test --clear-analysis using a supplied mnemonic' do
        oh = ObjectHealth.new(['-bat', '--limit=3', '--mnemonic=escholarship', '--clear-analysis'])
        expect(oh.options.fetch(:build_objects, false)).to be true
        expect(oh.options.fetch(:analyze_objects, false)).to be true
        expect(oh.options.fetch(:test_objects, false)).to be true

        oh.preliminary_tasks
        oh.process_objects

        verify_clear_counts(0, 1, 0)

        expect(oh.get_clear_query).to match(/where exists/)
        expect(oh.get_clear_query).to match(/escholarship/)
      end

      it 'test --clear-tests using the default collection' do
        oh = ObjectHealth.new(['-bat', '--limit=3', '--clear-tests'])
        expect(oh.options.fetch(:build_objects, false)).to be true
        expect(oh.options.fetch(:analyze_objects, false)).to be true
        expect(oh.options.fetch(:test_objects, false)).to be true

        oh.preliminary_tasks
        oh.process_objects

        verify_clear_counts(0, 0, 1)

        expect(oh.get_clear_query).to match(/where exists/)
        expect(oh.get_clear_query).to match(/merritt_demo/)
      end
    end

    describe 'Configure validation OFF' do
      before(:each) do
        @cfmc = ObjectHealthUtil.get_config(ObjectHealthUtil.merritt_classifications)
        @cfmc[:runtime][:validation] = false
      end

      it 'Verify validation OFF' do
        oh = ObjectHealth.new(cfmc: @cfmc)
        expect(oh.validation).to be false
      end

      it 'Verify validation on from command line' do
        oh = ObjectHealth.new(['--validation'], cfmc: @cfmc)
        expect(oh.validation).to be true
      end
    end

    describe 'Configure validation ON' do
      before(:each) do
        @cfmc = ObjectHealthUtil.get_config(ObjectHealthUtil.merritt_classifications)
        @cfmc[:runtime][:validation] = true
      end

      it 'Verify validation ON' do
        oh = ObjectHealth.new(cfmc: @cfmc)
        expect(oh.validation).to be true
      end

      it 'Verify validation off from command line' do
        oh = ObjectHealth.new(['--no-validation'], cfmc: @cfmc)
        expect(oh.validation).to be false
      end
    end
  end

  describe 'Test credential handling' do
    it 'Test Object Health Construction ... verify database and opensearch connection' do
      oh = ObjectHealth.new
      oh.get_object_list
    end

    it 'Test Object Health Usage in spite of bad credentials' do
      expect do
        ssm_override({ 'billing/readwrite/db-user': 'foo' })
        oh = ObjectHealth.new
        oh.get_object_list
      end.to raise_error(Mysql2::Error)
    end

    it 'Test Object Health Construction with bad db hostname' do
      expect do
        ssm_override({ 'billing/db-host': 'bad-host.cdlib.org' })
        oh = ObjectHealth.new
        oh.get_object_list
      end.to raise_error(Mysql2::Error)
    end

    it 'Test Object Health Construction with bad db credential' do
      expect do
        ssm_override({ 'billing/readwrite/db-user': 'foo' })
        oh = ObjectHealth.new
        oh.get_object_list
      end.to raise_error(Mysql2::Error)
    end

    it 'Test Object Health Construction - invalid opensearch credentials' do
      expect do
        ssm_override({ 'objhealth/opensearch_user': 'foo' })
        oh = ObjectHealth.new
      end.to raise_error(OpenSearch::Transport::Transport::Errors::Unauthorized)
    end

    it 'Test Object Health Construction - invalid opensearch host' do
      expect do
        ssm_override({ 'objhealth/opensearch_host': 'bad-host.cdlib.org' })
        oh = ObjectHealth.new
      end.to raise_error(Faraday::ConnectionFailed)
    end
  end
end
