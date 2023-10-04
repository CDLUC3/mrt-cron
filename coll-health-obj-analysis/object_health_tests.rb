require 'json'
require 'yaml'
require 'uc3-ssm'

class ObjectHealthTests
  def initialize(config)
    @config = config
  end

  def run_tests(obj)
    obj[:tests] = {PASS: 0, FAIL: 0}
    @config.fetch("tests", {}).each do |k,v|
      obj[:tests][k] = :PASS
      obj[:tests][:PASS] += 1
    end
    obj
  end
end
