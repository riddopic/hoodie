# encoding: UTF-8
#
# Author: Tom Santos <santos.tom@gmail.com>
# Author: Stefano Harding <riddopic@gmail.com>
#
# Copyright (C) 2012-2014 Tom Santos, Stefano Harding
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
  module Logging
    class << self

      # The Zero Log for Class
      class NoLogger < Logger
        def initialize(*args); end
        def add(*args, &block); end
      end

      def no_logger
        @log ||= NoLogger.new
      end

      def log(log_prefix)
        @log ||= Logger.new($stdout).tap do |log|
          log.progname = self.class == Class ? self.to_s : self.class.to_s
          log.formatter = Hoodie::Formatter.new
          log.formatter.datetime_format = '%F %T'
          log.level = Logger::DEBUG
        end
      end

      def log=(log)
        @log = log
      end

      def log_prefix
        self.class == Class ? self.to_s : self.class.to_s
      end

      def level
        "Logger::#{@level.to_s.upcase}"
      end
    end

    def self.included(base)
      class << base
        def log
          log_prefix = self.class == Class ? self.to_s : self.class.to_s
          Hoodie::Logging.log log_prefix
        end
      end
    end

    def log
      log_prefix = self.class == Class ? self.to_s : self.class.to_s
      Hoodie::Logging.log log_prefix
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
        format_datetime(time).BLUE,
        progname.CYAN,
        $$,
        severity.GREEN,
        msg2str(msg).strip.ORANGE
      ]
    end

    private #   P R O P R I E T À   P R I V A T A   Vietato L'accesso

    def format
      "%s [%s#%d] %5s: %s\n"
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

class String
  def clear;      colorize(self, "\e[0m");  end
  # Erase the current line of terminal output.
  def erase_line; colorize(self, "\e[K");   end
  # Erase the character under the cursor.
  def erase_char; colorize(self, "\e[P");   end
  # The start of an ANSI bold sequence.
  def bold;       colorize(self, "\e[1m");  end
  # The start of an ANSI dark sequence.
  def dark;       colorize(self, "\e[2m");  end
  # The start of an ANSI underline sequence.
  def underline;  colorize(self, "\e[4m");  end
  # The start of an ANSI blink sequence.
  def blink;      colorize(self, "\e[5m");  end
  # The start of an ANSI reverse sequence.
  def reverse;    colorize(self, "\e[7m");  end
  # The start of an ANSI concealed sequence.
  def concealed;  colorize(self, "\e[8m");  end

  # Set the terminal's foreground ANSI color to
  def BLACK;      colorize(self, "\e[0;30m"); end
  def GRAY;       colorize(self, "\e[1;30m"); end
  def RED;        colorize(self, "\e[0;31m"); end
  def MAGENTA;    colorize(self, "\e[1;31m"); end
  def GREEN;      colorize(self, "\e[0;32m"); end
  def OLIVE;      colorize(self, "\e[1;32m"); end
  def YELLOW;     colorize(self, "\e[0;33m"); end
  def CREAM;      colorize(self, "\e[1;33m"); end
  def BLUE;       colorize(self, "\e[0;34m"); end
  def PURPLE;     colorize(self, "\e[1;34m"); end
  def ORANGE;     colorize(self, "\e[0;35m"); end
  def MUSTARD;    colorize(self, "\e[1;35m"); end
  def CYAN;       colorize(self, "\e[0;36m"); end
  def CYAN2;      colorize(self, "\e[1;36m"); end
  def WHITE;      colorize(self, "\e[0;97m"); end

  # Set the terminal's background ANSI color to
  def on_black;   colorize(self, "\e[40m"); end
  def on_red;     colorize(self, "\e[41m"); end
  def on_green;   colorize(self, "\e[42m"); end
  def on_yellow;  colorize(self, "\e[43m"); end
  def on_blue;    colorize(self, "\e[44m"); end
  def on_magenta; colorize(self, "\e[45m"); end
  def on_cyan;    colorize(self, "\e[46m"); end
  def on_white;   colorize(self, "\e[47m"); end

  def colorize(text, color_code) "#{color_code}#{text}\e[0m" end
end
