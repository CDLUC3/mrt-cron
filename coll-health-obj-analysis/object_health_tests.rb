require 'json'
require_relative 'oh_tasktest'
Dir[File.dirname(__FILE__) + '/*_test.rb'].each {|file| require file }

class ObjectHealthTests
  def initialize(oh, config)
    @oh = oh
    @config = config
    @tests = []

    @config.fetch('tests', {}).each do |k,v|
      test = ObjHealthTest.create(@oh, v, k)
      @tests.append(test) unless test.nil?
    end

  end

  def run_tests(obj)
    tres = {failures: [], summary: '', test_run_log: []}
    ObjectHealth.status_values.each do |stat|
      tres[stat] = 0
    end
    obj[:tests] = obj.fetch(:tests, tres)
    obj[:tests][:test_run_log] = obj[:tests].fetch(:test_run_log, []).append(Time.now.to_s)
    @tests.each do |test|
      status = test.run_test(obj)
      obj[:tests][test.name] = status
      obj[:tests][status] += 1
      obj[:tests][:failures] = obj[:tests].fetch(:failures, []).append(test.name) if status == :FAIL
    end
    puts obj[:tests]
    obj
  end
end
