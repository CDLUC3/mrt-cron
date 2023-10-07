require 'json'
require 'yaml'
require 'uc3-ssm'

class ObjectHealthTests
  def initialize(config)
    @config = config
  end

  def run_tests(obj)
    obj[:tests] = {PASS: 0, FAIL: 0, failures: []}
    @config.fetch("tests", {}).each do |k,v|
      status = Random.new.rand(4) == 0 ? :FAIL : :PASS
      obj[:tests][k] = status
      obj[:tests][status] += 1
      obj[:tests][:failures].append(v.fetch('name', k)) if status == :FAIL
    end
    puts obj[:tests]
    obj
  end
end
