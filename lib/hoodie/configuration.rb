# encoding: UTF-8

module Hoodie

  # A Configuration instance
  class Configuration

    # Access the logging setting for this instance
    attr_accessor :logging

    # Access to the logging level for this instance
    attr_accessor :level

    # Initialized a configuration instance
    #
    # @return [undefined]
    #
    # @api private
    def initialize(options={})
      @logging = options.fetch(:logging, false)
      @level   = options.fetch(:level,   :info)

      yield self if block_given?
    end

    # @api private
    def to_h
      { logging: logging,
        level:   level
      }.freeze
    end
  end
end
