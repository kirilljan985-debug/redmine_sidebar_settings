# frozen_string_literal: true

module RedmineSidebarSettings
  # Own file so Zeitwerk can autoload the constant independently of Config
  # (tests and controllers may reference it before Config is ever loaded).
  class ValidationError < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super(errors.join('; '))
    end
  end
end
