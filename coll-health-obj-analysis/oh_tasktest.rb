# frozen_string_literal: true

require 'json'

# Base class for a Merritt Object Health ANALYSIS Task and TEST
class ObjHealthTask
  def initialize(objh, taskdef, name)
    @oh = objh
    @taskdef = taskdef
    scope = @taskdef.fetch(:collection_scope, {})
    @skip = scope.fetch(:skip, [])
    @apply = scope.fetch(:apply, [])
    @name = name
  end

  def check_scope(ohobj)
    m = ohobj.mnemonic
    return true if @apply.include?(m)
    return false if @skip.include?(m)

    @oh.collection_taxonomy(m).each do |g|
      return true if @apply.include?(g)
      return false if @skip.include?(g)
    end
    @apply.empty?
  end

  attr_reader :name

  def self.create(objh, taskdef, name)
    return if taskdef.nil?

    taskclass = taskdef.fetch(:class, '')
    Object.const_get(taskclass).new(objh, taskdef, name) unless taskclass.empty?
  end

  def run_task(ohobj)
    ohobj.analysis
  end

  def inspect
    to_s
  end
end

# Base class for a Merritt Object Health TEST
class ObjHealthTest < ObjHealthTask
  def run_test(_ohobj)
    :SKIP
  end

  def report_status(cond: nil)
    @taskdef.fetch(:report_status, {}).each do |k, v|
      return k if cond.nil? && v.nil?
      return k if v.nil?
      next if cond.nil?
      return k if cond == v.to_sym
      return k if cond == v
    end
    :SKIP
  end
end
