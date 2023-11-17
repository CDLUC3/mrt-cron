require 'spec_helper.rb'
require_relative '../object_health.rb'

RSpec.describe 'object health tests' do

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
end