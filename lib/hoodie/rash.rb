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

require 'hoodie'            unless defined?(Hoodie)
require 'anemone'           unless defined?(Anemone)
require 'hoodie/memoizable' unless defined?(Memoizable)

class Rash
  include Memoizable

  # Initializes a new store object.
  #
  # @param data [Hash] (optional) data to load into the stash.
  #
  # @return nothing.
  #
  def initialize(url, path)
    @url = url
    @path = path
    memoize [:fetch], Stash.new(DiskStash::Cache.new)
    @store ||= fetch
  end

  # Retrieves the value for a given key
  #
  # @param key [Symbol, String] representing the key
  #
  # @return [Hash, Array, String] value for key
  #
  def [](key)
    @store[key]
  end

  # Store the given value with the given key, either an an argument
  # or block. If a previous value was set it will be overwritten
  # with the new value.
  #
  # @param key [Symbol, String] string or symbol representing the key
  # @param value [Object] any object that represents the value (optional)
  # @param block [&block] that returns the value to set (optional)
  #
  # @return nothing.
  #
  def []=(key, value)
    @store[key] = value
  end

  # return the size of the store as an integer
  #
  # @return [Fixnum]
  #
  def size
    @store.size
  end

  # return all keys in the store as an array
  #
  # @return [Array<String, Symbol>] all the keys in store
  #
  def keys
    @store.keys
  end

  private #   P R O P R I E T À   P R I V A T A   Vietato L'accesso

  # Loads a rash hash of data into the rash or create a new one.
  #
  # @return nothing.
  #
  def fetch
    results = []
    Anemone.crawl(@url, discard_page_bodies: true) do |anemone|
      anemone.on_pages_like(/\/#{@path}\/\w+\/\w+\.(ini|zip)$/i) do |page|
        results << page.to_hash
      end
    end
    results.reduce({}, :recursive_merge)
  end
end

# to_hash smoke cache
#
module Anemone
  class Page
    def to_hash
      file  = ::File.basename(@url.to_s)
      key   = ::File.basename(file, '.*').downcase.to_sym
      type  = ::File.extname(file)[1..-1].downcase.to_sym
      id    = Hoodie::Obfuscate.befuddle(file, Digest::MD5.hexdigest(body.to_s))
      utime = Time::now.to_i
      key = { key => { type => {
        id:             id,
        file:           file,
        key:            key,
        type:           type,
        url:            @url.to_s,
        links:          links.map(&:to_s),
        code:           @code,
        visited:        @visited,
        depth:          @depth,
        referer:        @referer.to_s,
        fetched:        @fetched,
        utime:          utime,
        md5_digest:     Digest::MD5.hexdigest(body.to_s),
        sha256_digest:  Digest::SHA256.hexdigest(body.to_s)
      }}}
    end
  end
end
