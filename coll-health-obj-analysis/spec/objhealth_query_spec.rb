# frozen_string_literal: true

require 'spec_helper'
require 'logger'
require_relative '../object_health_util'
require_relative '../object_health_query'

RSpec.describe 'object health query tests' do
  before(:each) do
    ENV['OBJHEALTH_SILENT'] = 'Y'
  end

  describe 'Test command line options' do
    describe 'Usage test' do
      it 'Test Object Health Usage Exit' do
        allow($stdout).to receive(:write)
        expect do
          ObjectHealthQuery.new(['--help'])
        end.to raise_error(SystemExit)
      end

      it 'Test Object Health Query Usage' do
        expect do
          ObjectHealthQuery.new(['--help'])
        rescue SystemExit
          # intentional no action
        end.to output(/Usage:/).to_stdout
      end
    end

    describe 'Pagination params' do
      before(:each) do
        @arks = []
        @files = []
        @urls = []
        @fits_call = 0
        allow_any_instance_of(ConsoleOutput).to receive(:output).and_wrap_original do |_method, arg|
          @arks.append(arg[:ark])
          arg[:files].each do |f|
            @files.append(f[:path])
          end
        end
        allow_any_instance_of(FilesOutput).to receive(:output).and_wrap_original do |_method, arg|
          @arks.append(arg[:ark])
          arg[:files].each do |f|
            @urls.append(f[:url])
          end
        end
        allow_any_instance_of(FitsOutput).to receive(:format_fits_output).and_wrap_original do |_method, _arg|
          @fits_call += 1
        end
      end

      it 'Default pagination params' do
        ohq = ObjectHealthQuery.new([])
        ohq.run_query
        expect(@arks.length).to eq(10)
      end

      it 'Set pagination limit' do
        ohq = ObjectHealthQuery.new(['--limit=3'])
        ohq.run_query
        expect(@arks.length).to eq(3)
      end

      it 'Set pagination start' do
        ohq = ObjectHealthQuery.new(['--limit=10'])
        ohq.run_query
        expect(@arks.length).to eq(10)
        ark_save = @arks[2]
        @arks = []
        ohq = ObjectHealthQuery.new(['--limit=10', '--start=2'])
        ohq.run_query
        expect(@arks.length).to eq(10)
        expect(@arks[0]).to eq(ark_save)
      end

      it 'Query for non-existent collection' do
        ohq = ObjectHealthQuery.new(['--mnemonic=na'])
        ohq.run_query
        expect(@arks.length).to eq(0)
      end

      it 'Query for known collection with one object' do
        ohq = ObjectHealthQuery.new(['--mnemonic=cdl_ipresbo'])
        ohq.run_query
        expect(@arks.length).to eq(1)
      end

      it 'Query for known ark' do
        ohq = ObjectHealthQuery.new(['--ark=ark:/13030/m55v4d75'])
        ohq.run_query
        expect(@arks.length).to eq(1)
        expect(@files.length).to eq(0)
      end

      it 'Query for known ark (with 436 files), return files' do
        ohq = ObjectHealthQuery.new(['--ark=ark:/13030/m55v4d75', '--fmt=files'])
        ohq.run_query
        expect(@arks.length).to eq(1)
        expect(@files.length).to eq(436)
      end

      it 'Query for known ark (with 436 files), return 10 files' do
        ohq = ObjectHealthQuery.new(['--ark=ark:/13030/m55v4d75', '--fmt=files', '--max_file_per_object=10'])
        ohq.run_query
        expect(@arks.length).to eq(1)
        expect(@files.length).to eq(10)
      end

      it 'Query for known ark (with 436 files), return 10 file urls' do
        ohq = ObjectHealthQuery.new(
          [
            '--ark=ark:/13030/m55v4d75',
            '--fmt=files',
            '--output=files',
            '--max_file_per_object=10'
          ]
        )
        ohq.run_query
        expect(@arks.length).to eq(1)
        expect(@urls.length).to eq(10)
        @urls.each do |f|
          expect(f).to match(/^https/)
        end
      end

      it 'Query for known ark (with 436 files), return pdf files' do
        ohq = ObjectHealthQuery.new(['--ark=ark:/13030/m55v4d75', '--fmt=files', '--file_mime_regex="\.pdf"'])
        ohq.run_query
        expect(@arks.length).to eq(1)
        expect(@files.length).to be < 436
        @files.each do |f|
          expect(f).to match(/\.pdf/)
        end
      end

      it 'Query for known ark (with 436 files), return non-existent zzzpdf files' do
        ohq = ObjectHealthQuery.new(['--ark=ark:/13030/m55v4d75', '--fmt=files', '--file_mime_regex=\.zzzpdf'])
        ohq.run_query
        expect(@arks.length).to eq(1)
        expect(@files.length).to eq(0)
      end

      it 'Query for known ark (with 436 files), return file matched by path' do
        ohq = ObjectHealthQuery.new(
          [
            '--ark=ark:/13030/m55v4d75', '--fmt=files',
            '--file_path_regex=PLANETS_BROCHURE.pdf'
          ]
        )
        ohq.run_query
        expect(@arks.length).to eq(1)
        expect(@files.length).to eq(1)
      end

      it 'Query for known ark (with 436 files), call FITS for 2 files' do
        allow($stdout).to receive(:write)
        ohq = ObjectHealthQuery.new(['--ark=ark:/13030/m55v4d75', '--output=fits', '--max_file_per_object=2'])
        ohq.run_query
        expect(@fits_call).to eq(2)
      end
    end
  end
end
