# frozen_string_literal: true

class MySchemaException < StandardError
  def initialize(errors)
    @errors = errors
  end

  attr_reader :errors

  def print(label)
    puts "\n** Schema Validation Failure for #{label}"
    @errors.each do |s|
      puts " - #{s}"
    end
  end
end
