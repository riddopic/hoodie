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

module Hoodie
  module Inflections
    # A singleton instance of this class is yielded by Inflections.inflections,
    # which can then be used to specify additional inflection rules. Examples:
    #
    #   Inflections.inflections do |inflect|
    #     inflect.plural /^(ox)$/i, '\1\2en'
    #     inflect.singular /^(ox)en/i, '\1'
    #
    #     inflect.irregular 'octopus', 'octopi'
    #
    #     inflect.uncountable "equipment"
    #   end
    #
    # New rules are added at the top. So in the example above, the irregular
    # rule for octopus will now be the first of the pluralization and
    # singularization rules that is runs. This guarantees that your rules run
    # before any of the rules that may already have been loaded.
    #
    class Inflections

      # Return instance
      #
      # @return [Inflections]
      # @api private
      def self.instance
        @__instance__ ||= new
      end

      # @return [Array] plurals
      # @api private
      attr_reader :plurals

      # @return [Array] singulars
      # @api private
      attr_reader :singulars

      # @return [Array] uncountables
      # @api private
      attr_reader :uncountables

      # @return [Array] humans
      # @api private
      attr_reader :humans

      # Initialize object
      #
      # @return [undefined]
      # @api private
      def initialize
        @plurals      = RulesCollection.new
        @singulars    = RulesCollection.new
        @humans       = RulesCollection.new
        @uncountables = Set[]
      end

      # Specifies a new pluralization rule and its replacement. The rule can
      # either be a string or a regular expression. The replacement should
      # always be a string that may include references to the matched data from
      # the rule.
      #
      # @param [String, Regexp] rule
      # @param [String, Regexp] replacement
      # @return [self]
      # @api private
      def plural(rule, replacement)
        rule(rule, replacement, @plurals)
        self
      end

      # Specifies a new singularization rule and its replacement. The rule can
      # either be a string or a regular expression. The replacement should
      # always be a string that may include references to the matched data from
      # the rule.
      #
      # @param [String, Regexp] rule
      # @param [String, Regexp] replacement
      # @return [self]
      # @api private
      def singular(rule, replacement)
        rule(rule, replacement, @singulars)
        self
      end

      # Specifies a new irregular that applies to both pluralization and
      # singularization at the same time. This can only be used for strings, not
      # regular expressions. You simply pass the irregular in singular and
      # plural form.
      #
      # @param [String] singular
      # @param [String] plural
      # @return [self]
      # @api private
      def irregular(singular, plural)
        @uncountables.delete(singular)
        @uncountables.delete(plural)
        add_irregular(singular, plural, @plurals)
        add_irregular(plural, singular, @singulars)
        self
      end

      # Uncountable will not be inflected
      #
      # @param [Enumerable<String>] words
      # @return [self]
      # @api private
      def uncountable(*words)
        @uncountables.merge(words.flatten)
        self
      end

      # Specifies a humanized form of a string by a regular expression rule or
      # by a string mapping. When using a regular expression based replacement,
      # the normal humanize formatting is called after the replacement. When a
      # string is used, the human form should be specified as desired (example:
      # 'The name', not 'the_name')
      #
      # @param [String, Regexp] rule
      # @param [String, Regexp] replacement
      # @return [self]
      # @api private
      def human(rule, replacement)
        @humans.insert(0, [rule, replacement])
        self
      end

      # Clear all inflection rules
      #
      # @return [self]
      # @api private
      def clear
        initialize
        self
      end

      private

      # Add irregular inflection
      #
      # @param [String] rule
      # @param [String] replacement
      # @return [undefined]
      # @api private
      def add_irregular(rule, replacement, target)
        head, *tail = rule.chars.to_a
        rule(/(#{head})#{tail.join}\z/i, '\1' + replacement[1..-1], target)
      end

      # Add a new rule
      #
      # @param [String, Regexp] rule
      # @param [String, Regexp] replacement
      # @param [Array] target
      # @return [undefined]
      # @api private
      def rule(rule, replacement, target)
        @uncountables.delete(rule)
        @uncountables.delete(replacement)
        target.insert(0, [rule, replacement])
      end
    end
  end
end
