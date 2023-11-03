require 'json'
require_relative 'oh_tasktest'
Dir[File.dirname(__FILE__) + '/*_task.rb'].each {|file| require file }

class AnalysisTasks
  def initialize(oh, config)
    @oh = oh
    @config = config
    @tasks = []

    analysis = @config.fetch(:analysis_json, {})
    analysis.each do |k,v|
      task = ObjHealthTask.create(@oh, v, k)
      @tasks.append(task) unless task.nil?
    end
  end

  def run_tasks(ohobj)
    ohobj.analysis.init_object
    @tasks.each do |task|
      task.run_task(ohobj) if task.check_scope(ohobj)
    end
    ohobj
  end
    
end