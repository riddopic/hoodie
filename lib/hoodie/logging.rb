
require 'logger'
require 'time'

module Hoodie
  module Logging
    class << self
      def log
        @log ||= Logger.new($stdout).tap do |log|
          log.progname = 'Hoodie'
          log.level = Logger::INFO
          log.formatter = Hoodie::Formatter.new
        end
      end

      def log=(log)
        @log = log
      end
    end

    def self.included(base)
      class << base
        def log
          Hoodie::Logging.log
        end
      end
    end

    def log
      Hoodie::Logging.log
    end
  end

  class Formatter < ::Logger::Formatter
    def initialize
      super
    end

    def call(severity, time, progname, msg)
      format % [time, progname, $$, severity, msg2str(msg).strip]
    end

    private #   P R O P R I E T À   P R I V A T A   Vietato L'accesso

    def format
      "%s [%s#%d] %5s: %s\n"
    end
  end
end


include Hoodie::Logging
