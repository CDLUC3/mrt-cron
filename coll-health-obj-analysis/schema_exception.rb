# frozen_string_literal: true

# conveys a JSON schema valdiation failure
class MySchemaException < StandardError
  def initialize(errors)
    @errors = errors
    super
  end

  attr_reader :errors

  def print(label)
    puts "\n** Schema Validation Failure for #{label}"
    @errors.each do |s|
      puts " - #{s}"
    end
  end
end
