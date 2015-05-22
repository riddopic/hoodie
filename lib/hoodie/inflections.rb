# encoding: UTF-8
#
# Author:    Stefano Harding <riddopic@gmail.com>
# License:   Apache License, Version 2.0
# Copyright: (C) 2014-2015 Stefano Harding
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

require 'set'

module Hoodie
  # The Inflections transforms words from singular to plural, class names to
  # table names, modularized class names to ones without, and class names to
  # foreign keys. The default inflections for pluralization, singularization,
  # and uncountable words are kept in inflections.rb.
  #
  module Inflections
    # Convert input to UpperCamelCase. Will also convert '/' to '::' which is
    # useful for converting paths to namespaces.
    #
    # @param [String] input
    #
    # @return [String]
    #
    def self.camelize(input)
      input.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:\A|_)(.)/) {$1.upcase}
    end

    # Convert input to underscored, lowercase string. Changes '::' to '/' to
    # convert namespaces to paths.
    #
    # @param [String] input
    #
    # @return [String]
    #
    def self.underscore(input)
      word = input.gsub(/::/, '/')
      underscorize(word)
    end

    # Convert input underscores to dashes.
    #
    # @param [String] input
    #
    # @return [String]
    #
    def self.dasherize(input)
      input.tr('_', '-')
    end

    # Return unscoped constant name.
    #
    # @param [String] input
    #
    # @return [String]
    #
    def self.demodulize(input)
      input.split('::').last
    end

    # Creates a foreign key name
    #
    # @param [String] input
    #
    # @return [String]
    #
    def self.foreign_key(input)
      "#{underscorize(demodulize(input))}_id"
    end

    # Find a constant with the name specified in the argument string. The name
    # is assumed to be the one of a top-level constant, constant scope of
    # caller is igored.
    #
    # @param [String] input
    #
    # @return [Class, Module]
    #
    def self.constantize(input)
      names = input.split('::')
      names.shift if names.first.empty?

      names.inject(Object) do |constant, name|
        if constant.const_defined?(name)
          constant.const_get(name)
        else
          constant.const_missing(name)
        end
      end
    end

    ORDINALIZE_TH = (4..16).to_set.freeze

    # Convert a number into an ordinal string.
    #
    # @param [Fixnum] number
    #
    # @return [String]
    #
    def self.ordinalize(number)
      abs_value = number.abs

      if ORDINALIZE_TH.include?(abs_value % 100)
        "#{number}th"
      else
        case abs_value % 10
          when 1; "#{number}st"
          when 2; "#{number}nd"
          when 3; "#{number}rd"
        end
      end
    end

    # Convert input word string to plural
    #
    # @param [String] word
    #
    # @return [String]
    #
    def self.pluralize(word)
      return word if uncountable?(word)
      inflections.plurals.apply_to(word)
    end

    # Convert word to singular
    #
    # @param [String] word
    #
    # @return [String]
    #
    def self.singularize(word)
      return word if uncountable?(word)
      inflections.singulars.apply_to(word)
    end

    # Humanize string.
    #
    # @param [String] input
    #
    # @return [String]
    #
    def self.humanize(input)
      result = inflections.humans.apply_to(input)
      result.gsub!(/_id\z/, "")
      result.tr!('_', " ")
      result.capitalize!
      result
    end

    # Tabelize input string.
    #
    # @param [String] input
    #
    # @return [String]
    #
    def self.tableize(input)
      pluralize(underscore(input).gsub('/', '_'))
    end

    # Create a class name from a plural table name like Rails does for table
    # names to models.
    #
    # @param [String] input
    #
    # @return [String]
    #
    def self.classify(table_name)
      camelize(singularize(table_name.sub(/.*\./, '')))
    end

    # Create a snake case string with an optional namespace prepended.
    #
    # @param [String] input
    #
    # @param [String] namespace
    #
    # @return [String]
    #
    def self.snakeify(input, namespace = nil)
      input = input.dup
      input.sub!(/^#{namespace}(\:\:)?/, '') if namespace
      input.gsub!(/[A-Z]/) {|s| "_" + s}
      input.downcase!
      input.sub!(/^\_/, "")
      input
    end

    # Test if word is uncountable.
    #
    # @param [String] word
    #
    # @return [Boolean] true, if word is uncountable
    #
    def self.uncountable?(word)
      word.empty? || inflections.uncountables.include?(word.downcase)
    end

    # Convert input to underscored, lowercase string
    #
    # @param [String] input
    #
    # @return [String]
    #
    def self.underscorize(word)
      word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!('-', '_')
      word.downcase!
      word
    end
    private_class_method :underscorize

    # Yields a singleton instance of Garcon::Inflections.
    #
    # @return [Garcon::Inflections]
    #
    def self.inflections
      instance = Inflections.instance
      block_given? ? yield(instance) : instance
    end
  end
end

require_relative 'inflections/rules_collection'
require_relative 'inflections/inflections'
require_relative 'inflections/defaults'
