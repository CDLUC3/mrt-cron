require 'json'
require 'yaml'
require 'uc3-ssm'
require_relative 'object_health_db'
require_relative 'object_health_tests'

class ObjectHealth
  def initialize
    config_file = 'config/database.ssm.yml'
    @config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: config_file, resolve_key: 'default', return_key: 'default')
    @obj_health_db = ObjectHealthDb.new(@config.fetch('dbconf', {}))
    @obj_health_tests = ObjectHealthTests.new(@config)
  end

  def processObjects
    @obj_health_db.get_object_list.each do |id|
      processObject(id)
    end
  end

  def export_object(obj)
    File.open("#{ENV['COLLHDATA']}/objects_details.ndjson", 'a') do |f|
      f.write(obj.to_json)
      f.write("\n")
    end
  end

  def processObject(id)
    obj = @obj_health_db.get_object(id)
    @obj_health_db.update_object(id, obj)
    obj = @obj_health_tests.run_tests(obj)
    export_object(obj)
  end
end

oh = ObjectHealth.new
oh.processObjects