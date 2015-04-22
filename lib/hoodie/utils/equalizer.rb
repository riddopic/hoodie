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
  # Define equality, equivalence and inspection methods.
  #
  class Equalizer

    # Initialize an Equalizer with the given keys.
    #
    # Will use the keys with which it is initialized to define #cmp?,
    # #hash, and #inspect
    #
    # @param [String] name
    #
    # @param [Array<Symbol>] keys
    #
    # @return [undefined]
    #
    # @api private
    def initialize(name, keys = [])
      @name = name.dup.freeze
      @keys = keys.dup
      define_methods
      include_comparison_methods
    end

    # Append a key and compile the equality methods.
    #
    # @return [Equalizer] self
    #
    # @api private
    def <<(key)
      @keys << key
      self
    end

    private #        P R O P R I E T À   P R I V A T A   Vietato L'accesso

    # Define the equalizer methods based on #keys.
    #
    # @return [undefined]
    #
    # @api private
    def define_methods
      define_cmp_method
      define_hash_method
      define_inspect_method
    end

    # Define an #cmp? method based on the instance's values identified by #keys.
    #
    # @return [undefined]
    #
    # @api private
    def define_cmp_method
      keys = @keys
      define_method(:cmp?) do |comparator, other|
        keys.all? { |key| send(key).send(comparator, other.send(key)) }
      end
    end

    # Define a #hash method based on the instance's values identified by #keys.
    #
    # @return [undefined]
    #
    # @api private
    def define_hash_method
      keys = @keys
      define_method(:hash) do
        keys.map { |key| send(key) }.push(self.class).hash
      end
    end

    # Define an inspect method that reports the values of the instance's keys.
    #
    # @return [undefined]
    #
    # @api private
    def define_inspect_method
      name, keys = @name, @keys
      define_method(:inspect) do
        "#<#{name}#{keys.map { |key| " #{key}=#{send(key).inspect}" }.join}>"
      end
    end

    # Include the #eql? and #== methods
    #
    # @return [undefined]
    #
    # @api private
    def include_comparison_methods
      module_eval { include Methods }
    end

    # The comparison methods
    module Methods

      # Compare the object with other object for equality.
      #
      # @example
      #   object.eql?(other)  # => true or false
      #
      # @param [Object] other
      #   the other object to compare with
      #
      # @return [Boolean]
      #
      # @api public
      def eql?(other)
        instance_of?(other.class) && cmp?(__method__, other)
      end

      # Compare the object with other object for equivalency.
      #
      # @example
      #   object == other  # => true or false
      #
      # @param [Object] other
      #   the other object to compare with
      #
      # @return [Boolean]
      #
      # @api public
      def ==(other)
        other.kind_of?(self.class) && cmp?(__method__, other)
      end
    end
  end
end
