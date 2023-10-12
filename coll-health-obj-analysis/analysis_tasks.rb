require 'json'
require_relative 'oh_tasktest'
Dir[File.dirname(__FILE__) + '/*_task.rb'].each {|file| require file }

class AnalysisTasks
  def initialize(oh, config)
    @oh = oh
    @config = config
    @tasks = []

    @config.fetch('analysis-json', {}).each do |k,v|
      task = ObjHealthTask.create(@oh, v, k)
      @tasks.append(task) unless task.nil?
    end
  end

  def run_tasks(obj)
    ares = {}
    obj[:analysis] = obj.fetch(:analysis, ares)
    @tasks.each do |task|
      obj = task.run_task(obj)
    end
    puts obj[:analysis]
    obj
  end
    
end