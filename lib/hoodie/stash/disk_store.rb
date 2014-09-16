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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied. See the License for the specific language governing
# permissions and limitations under the License.
#

require 'tmpdir'

module DiskStash
	# Disk stashing method variable caching hash, string, array store.
	class Cache
		include Enumerable

    # @return [String] location of DiskStash::Cache.store
    #
    attr_reader :store

    # Initializes a new disked backed stash hash cache store.
    #
    # @param path [String] location for stash store cache.
    #
    # @return nothing.
    #
    def initialize(store = file_store)
    	@store = store
      _ensure_store_directory
    end

	  # Clear the whole stash or the value of a key
	  #
	  # @param key [Symbol, String] (optional) string or symbol
    # representing the key to clear
	  #
	  # @return [Hash] with a key, return the value it had, without
    # returns {}
	  #
    def clear!(key = nil)
      if key.nil?
        ::Dir[::File.join(store, '*.cache')].each do |file|
          ::File.delete(file)
        end
      else
        ::File.delete(cache_file(key)) if ::File.exists?(cache_file(key))
      end
    end

		# Retrieves the value for a given key, if nothing is set,
    # returns nil
    #
    # @param key [Symbol, String] representing the key
    #
    # @return [Hash, Array, String] value for key
    #
    def [](key)
      if key.is_a? Array
        hash = {}
        key.each do |k|
          hash[k] = Marshal::load(_read_cache_file(k))
        end
        hash unless hash.empty?
      else
        Marshal::load(_read_cache_file(key))
      end
    rescue Errno::ENOENT
      nil # key hasn't been created
    end

    # Store the given value with the given key, either an an argument
    # or block. If a previous value was set it will be overwritten
    # with the new value.
    #
    # @param key [Symbol, String] representing the key
    # @param value [Object] that represents the value (optional)
    # @param block [&block] that returns the value to set (optional)
    #
    # @return nothing.
    #
    def []=(key, value)
    	_write_cache_file(key, Marshal::dump(value))
    end

		# returns path to cache file with 'key'
	  def cache_file key
	  	::File.join(store, key.to_s + '.cache')
	  end

		private #   P R O P R I E T À   P R I V A T A   divieto di accesso

    # return Chef tmpfile path if running under Chef, else return OS
    # temp path. On Winders Dir.tmpdir returns the correct path.
    #
    def file_store
      if OS.windows?
        win_friendly_path('/chef/._stash_')
      else
        ::File.join('var', 'lib', '._stash')
      end
    end

    # returns windows friendly version of the provided path, ensures
    # backslashes are used everywhere
    #
    def win_friendly_path(path)
      system_drive = ENV['SYSTEMDRIVE'] ? ENV['SYSTEMDRIVE'] : ""
      path = ::File.join(system_drive, path)
      path.gsub!(::File::SEPARATOR, (::File::ALT_SEPARATOR || '\\'))
    end

    def _write_cache_file(key, content)
      f = ::File.open(cache_file(key), 'wb' )
      f.flock(::File::LOCK_EX)
      f.write(content)
      f.close
      content
    end

    def _read_cache_file(key)
    	f = ::File.open(cache_file(key), 'rb')
    	f.flock(::File::LOCK_SH)
    	out = f.read
    	f.close
    	out
    end

	  def read_cache_mtime(key)
	  	nil unless ::File.exists?(cache_file(key))
	  	::File.mtime(cache_file(key))
	  end

	  def _ensure_store_directory
	  	::Dir.mkdir(store) unless ::File.directory?(store)
	  end
	end
end
