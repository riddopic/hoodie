# encoding: UTF-8
#
# Author: Stefano Harding <riddopic@gmail.com>
#
# Copyright (C) 2014-2015 Stefano Harding
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'logger'
require 'time'

module Hoodie
  module Log
    @loggers ||= {}

    def demodulize(class_name_in_module)
      class_name_in_module.to_s.sub(/^.*::/, '')
    end

    class << self

      class NoLogger < Logger
        def initialize(*args)
        end

        def add(*args, &block)
        end
      end

      def demodulize(class_name_in_module)
        class_name_in_module.to_s.sub(/^.*::/, '')
      end

      def log(prefix)
        @loggers[prefix] ||= logger_for(prefix)
      end

      def logger_for(prefix)

        log = logger
        log.progname = prefix
        log.formatter = Hoodie::Formatter.new
        log.formatter.datetime_format = '%F %T'
        log.level = self.send(log_level)
        log
      end

      def log=(log)
        @log = log
      end

      def logger
        Hoodie.configuration.logging ? Logger.new($stdout) : NoLogger.new
      end

      def log_level
        "Logger::#{Hoodie.configuration.level.to_s.upcase}"
      end
    end

    def self.included(base)
      class << base
        def log
          prefix = self.class == Class ? self.to_s : self.class.to_s
          Hoodie::Logging.log(demodulize(prefix))
        end
      end
    end

    def log
      prefix = self.class == Class ? self.to_s : self.class.to_s
      Hoodie::Logging.log(demodulize(prefix))
    end
  end

  class Formatter < Logger::Formatter
    attr_accessor :datetime_format

    def initialize
      @datetime_format = nil
      super
    end

    def call(severity, time, progname, msg)
      format % [
        format_datetime(time).blue,
        severity.green,
        msg2str(msg).strip.orange
      ]
    end

    private #   P R O P R I E T À   P R I V A T A   Vietato L'accesso

    def format
      "[%s] %5s: %s\n"
    end

    def format_datetime(time)
      if @datetime_format.nil?
        time.strftime("%Y-%m-%dT%H:%M:%S.") << "%06d " % time.usec
      else
        time.strftime(@datetime_format)
      end
    end
  end
end
