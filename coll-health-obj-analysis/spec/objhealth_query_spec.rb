require 'spec_helper'
require 'logger'
require_relative '../object_health_util'
require_relative '../object_health_query'

RSpec.describe 'object health query tests' do
  before(:each) do
    ENV['OBJHEALTH_SILENT'] = 'Y'
  end


  describe "Test command line options" do

    describe "Usage test" do
      it "Test Object Health Usage Exit" do

        allow($stdout).to receive(:write)
        expect {
          oh = ObjectHealthQuery.new(['--help'])
        }.to raise_error(SystemExit)
      end
    
      it "Test Object Health Query Usage" do
        expect {
          begin
            oh = ObjectHealthQuery.new(['--help'])
          rescue SystemExit
          end
        }.to output(%r[Usage:]).to_stdout
      end
    end

  end
  
end