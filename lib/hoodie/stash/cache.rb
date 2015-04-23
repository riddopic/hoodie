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
  module Stash
    # Disk stashing method variable caching hash, string, array store.
    #
    # Key/value cache store
    class Cache

      # @!attribute [r] :store
      #   @return [Stash] location of Stash store object.
      attr_reader :store

      # Initializes a new empty store
      #
      def initialize(params = {})
        params = { store: params } unless params.is_a? Hash
        @store = params.fetch(:store) { DEFAULT_STORE }
      end

      # Clear the whole stash store or the value of a key
      #
      # @param key [Symbol, String] (optional) representing the key to
      # clear.
      #
      # @return nothing.
      #
      def clear!(key = nil)
        key = key.to_sym unless key.nil?
        @store.clear! key
      end

      # Retrieves the value for a given key, if nothing is set,
      # returns KeyError
      #
      # @param key [Symbol, String] representing the key
      #
      # @raise [KeyError] if no such key found
      #
      # @return [Hash, Array, String] value for key
      #
      def [](key = nil)
        key ||= Stash.caller_name
        fail KeyError, 'Key not cached' unless include? key.to_sym
        @store[key.to_sym]
      end

      # Retrieves the value for a given key, if nothing is set,
      # run the code, cache the result, and return it
      #
      # @param key [Symbol, String] representing the key
      # @param block [&block] that returns the value to set (optional)
      #
      # @return [Hash, Array, String] value for key
      #
      def cache(key = nil, &code)
        key ||= Stash.caller_name
        @store[key.to_sym] ||= code.call
      end

      # return the size of the store as an integer
      #
      # @return [Fixnum]
      #
      def size
        @store.size
      end

      # return a boolean indicating presence of the given key in the store
      #
      # @param key [Symbol, String] a string or symbol representing the key
      #
      # @return [Boolean]
      #
      def include?(key = nil)
        key ||= Stash.caller_name
        @store.include? key.to_sym
      end
    end
  end
end
