# encoding: UTF-8
#
# Author: Stefano Harding <riddopic@gmail.com>
#
# Copyright (C) 2014 Stefano Harding
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

class Hash
  # Returns a compacted copy (contains no key/value pairs having
  # nil? values)
  #
  # @example
  #     hash = { a: 100, b: nil, c: false, d: '' }
  #     hash.compact # => { a: 100, c: false, d: '' }
  #     hash         # => { a: 100, b: nil, c: false, d: '' }
  #
  # @return [Hash]
  #
  def compact
    select { |_, value| !value.nil? }
  end

  # Returns a new hash with all keys converted using the block operation.
  #
  # @example
  #     hash = { name: 'Tiggy', age: '15' }
  #
  #     hash.transform_keys{ |key| key.to_s.upcase }
  #                 # => { "AGE" => "15", "NAME" => "Tiggy" }
  #
  # @return [Hash]
  #
  def transform_keys
    return enum_for(:transform_keys) unless block_given?
    result = self.class.new
    each_key do |key|
      result[yield(key)] = self[key]
    end
    result
  end

  # Returns a new hash, recursively converting all keys by the
  # block operation.
  #
  # @return [Hash]
  #
  def recursively_transform_keys(&block)
    _recursively_transform_keys_in_object(self, &block)
  end

  # Returns a new hash with all keys downcased and converted
  # to symbols.
  #
  # @return [Hash]
  #
  def normalize_keys
    transform_keys { |key| key.downcase.to_sym rescue key }
  end

  # Returns a new Hash, recursively downcasing and converting all
  # keys to symbols.
  #
  # @return [Hash]
  #
  def recursively_normalize_keys
    recursively_transform_keys { |key| key.downcase.to_sym rescue key }
  end

  # Returns a new hash with all keys converted to symbols.
  #
  # @return [Hash]
  #
  def symbolize_keys
    transform_keys { |key| key.to_sym rescue key }
  end

  # Returns a new Hash, recursively converting all keys to symbols.
  #
  # @return [Hash]
  #
  def recursively_symbolize_keys
    recursively_transform_keys { |key| key.downcase.to_sym rescue key }
  end

  # Returns a new hash with all keys converted to strings.
  #
  # @return [Hash]
  #
  def stringify_keys
    transform_keys { |key| key.to_s rescue key }
  end

  # Returns a new Hash, recursively converting all keys to strings.
  #
  # @return [Hash]
  #
  def recursively_stringify_key
    recursively_transform_keys { |key| key.to_s rescue key }
  end

  class UndefinedPathError < StandardError; end
  # Recursively searchs a nested datastructure for a key and returns
  # the value. If a block is provided its value will be returned if
  # the key does not exist
  #
  # @example
  #     options = { server: { location: { row: { rack: 34 } } } }
  #     options.recursive_fetch :server, :location, :row, :rack
  #                 # => 34
  #     options.recursive_fetch(:non_existent_key) { 'default' }
  #                 # => "default"
  #
  # @return [Hash, Array, String] value for key
  #
  def recursive_fetch(*args, &block)
    args.reduce(self) do |obj, arg|
      begin
        arg = Integer(arg) if obj.is_a? Array
        obj.fetch(arg)
      rescue ArgumentError, IndexError, NoMethodError => e
        break block.call(arg) if block
        raise UndefinedPathError, "Could not fetch path (#{args.join(' > ')}) at #{arg}", e.backtrace
      end
    end
  end

  def recursive_merge(other)
    hash = dup
    other.each do |key, value|
      myval = self[key]
      if value.is_a?(Hash) && myval.is_a?(Hash)
        hash[key] = myval.recursive_merge(value)
      else
        hash[key] = value
      end
    end
    hash
  end

  private #   P R O P R I E T À   P R I V A T A   divieto di accesso

  # support methods for recursively transforming nested hashes and arrays
  def _recursively_transform_keys_in_object(object, &block)
    case object
    when Hash
      object.each_with_object({}) do |(key, value), result|
        result[yield(key)] = _recursively_transform_keys_in_object(value, &block)
      end
    when Array
      object.map { |e| _recursively_transform_keys_in_object(e, &block) }
    else
      object
    end
  end
end
