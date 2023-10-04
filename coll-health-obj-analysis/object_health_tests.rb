require 'json'
require 'yaml'
require 'uc3-ssm'

class ObjectHealthTests
  def initialize(config)
    @config = config
  end

  def run_tests(obj)
    obj[:tests] = {}
    obj
  end
end
