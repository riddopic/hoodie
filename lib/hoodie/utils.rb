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

require 'securerandom'
require 'time'

module Hoodie
  module Utils
    def self.included(base)
      include(ClassMethods)

      base.send(:include, ClassMethods)
    end
    private_class_method :included

    module ClassMethods
      def callable(call_her)
        call_her.respond_to?(:call) ? call_her : lambda { call_her }
      end

      def camelize(underscored_word)
        underscored_word.to_s.gsub(/(?:^|_)(.)/) { $1.upcase }
      end

      def classify(table_name)
        camelize singularize(table_name.to_s.sub(/.*\./, ''))
      end

      def class_name
        demodulize(self.class)
      end

      def caller_name(position = 0)
        caller[position][/`.*'/][1..-2]
      end

      def demodulize(class_name_in_module)
        class_name_in_module.to_s.sub(/^.*::/, '')
      end

      def pluralize(word)
        word.to_s.sub(/([^s])$/, '\1s')
      end

      def singularize(word)
        word.to_s.sub(/s$/, '').sub(/ie$/, 'y')
      end

      def underscore(camel_cased_word)
        word = camel_cased_word.to_s.dup
        word.gsub!(/::/, '/')
        word.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
        word.tr! '-', '_'
        word.downcase!
        word
      end

      # Return the date and time in "HTTP-date" format as defined by RFC 7231.
      #
      # @return [Date,Time] in "HTTP-date" format
      def utc_httpdate
        Time.now.utc.httpdate
      end

      def request_id
        SecureRandom.uuid
      end

      def twenty_four_hours_ago
        Time.now - ( 60 * 60 * 24)
      end

      def verify_options(accepted, actual) # @private
        return unless debug || $DEBUG
        unless (act=Set[*actual.keys]).subset?(acc=Set[*accepted])
          raise Croesus::Errors::UnknownOption,
            "\nDetected unknown option(s): #{(act - acc).to_a.inspect}\n" <<
            "Accepted options are: #{accepted.inspect}"
        end
        yield if block_given?
      end

      # Returns the columns and lines of the current tty.
      #
      # @return [Integer]
      #   number of columns and lines of tty, returns [0, 0] if no tty present.
      #
      # @api public
      def terminal_dimensions
        [0, 0] unless  STDOUT.tty?
        [80, 40] if OS.windows?

        if ENV['COLUMNS'] && ENV['LINES']
          [ENV['COLUMNS'].to_i, ENV['LINES'].to_i]
        elsif ENV['TERM'] && command_in_path?('tput')
          [`tput cols`.to_i, `tput lines`.to_i]
        elsif command_in_path?('stty')
          `stty size`.scan(/\d+/).map {|s| s.to_i }
        else
          [0, 0]
        end
      rescue
        [0, 0]
      end

      # Checks in PATH returns true if the command is found
      def command_in_path?(command)
        found = ENV['PATH'].split(File::PATH_SEPARATOR).map do |p|
          File.exist?(File.join(p, command))
        end
        found.include?(true)
      end

      # Runs a code block, and retries it when an exception occurs. Should the
      # number of retries be reached without success, the last exception will be
      # raised.
      #
      # @param opts [Hash{Symbol => Value}]
      # @option opts [Fixnum] :tries
      #   number of attempts to retry before raising the last exception
      # @option opts [Fixnum] :sleep
      #   number of seconds to wait between retries, use lambda to exponentially
      #   increasing delay between retries
      # @option opts [Array(Exception)] :on
      #   the type of exception(s) to catch and retry on
      # @option opts [Regex] :matching
      #   match based on the exception message
      # @option opts [Block] :ensure
      #   ensure a block of code is executed, regardless of whether an exception
      #   is raised
      #
      # @return [Block]
      #
      def retrier(opts = {}, &block)
        defaults = {
          tries:    2,
          sleep:    1,
          on:       StandardError,
          matching: /.*/,
          :ensure => Proc.new {}
        }

        check_for_invalid_options(opts, defaults)
        defaults.merge!(opts)

        return if defaults[:tries] == 0

        on_exception, tries = [defaults[:on]].flatten, defaults[:tries]
        retries = 0
        retry_exception = nil

        begin
          yield retries, retry_exception
        rescue *on_exception => exception
          raise unless exception.message =~ defaults[:matching]
          raise if retries+1 >= defaults[:tries]

          # Interrupt Exception could be raised while sleeping
          begin
            sleep defaults[:sleep].respond_to?(:call) ?
              defaults[:sleep].call(retries) : defaults[:sleep]
          rescue *on_exception
          end

          retries += 1
          retry_exception = exception
          retry
        ensure
          defaults[:ensure].call(retries)
        end
      end

      private #   P R O P R I E T À   P R I V A T A   Vietato L'accesso

      def check_for_invalid_options(custom_options, defaults)
        invalid_options = defaults.merge(custom_options).keys - defaults.keys
        raise ArgumentError.new('[Retrier] Invalid options: ' \
          "#{invalid_options.join(", ")}") unless invalid_options.empty?
      end
    end
  end
end
