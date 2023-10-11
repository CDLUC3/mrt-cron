require 'json'
require 'yaml'
require 'uc3-ssm'

class ObjectHealthTests
  def initialize(config)
    @config = config
  end

  def run_tests(obj)
    puts obj[:tests]
    tres = {SKIP: 0, PASS: 0, INFO: 0, WARN: 0, FAIL: 0, failures: [], summary: '', test_run_log: []}
    obj[:tests] = obj.fetch(:tests, tres)
    puts obj[:tests]
    puts obj[:tests][:test_run_log].class
    obj[:tests][:test_run_log] = obj[:tests].fetch(:test_run_log, []).append(Time.now.to_s)
    @config.fetch("tests", {}).each do |k,v|
      status = Random.new.rand(4) == 0 ? :FAIL : :PASS
      obj[:tests][k] = status
      obj[:tests][status.to_sym] += 1
      obj[:tests][:failures] = obj[:tests].fetch(:failures, []).append(v.fetch('name', k)) if status == :FAIL
    end
    puts obj[:tests][:test_run_log]
    obj
  end
end
