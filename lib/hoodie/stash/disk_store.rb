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

require 'tmpdir'

module Hoodie
  # Disk stashing method variable caching hash, string, array store.
  #
  class Stash
    class DiskStash

      # @!attribute [r] :store
      #   @return [Stash::DiskStore] location of Stash::DiskStore store.
      attr_reader :store

      # Initializes a new disked backed stash hash cache store.
      #
      # @param path [String] location for stash store cache.
      #
      # @return nothing.
      #
      def initialize(store = file_store)
        @store = store
      end

      # Retrieves a value from the cache, if available and not expired, or
      # yields to a block that calculates the value to be stored in the cache.
      #
      # @param [Object] key
      #   The key to look up or store at.
      #
      # @yield yields when the value is not present.
      #
      # @yieldreturn [Object]
      #   The value to store in the cache.
      #
      # @return [Object]
      #   The value at the key.
      #
      def cache(key = nil, &code)
        key ||= Stash.caller_name
        @store[key.to_sym] ||= code.call
      end

      # Clear the whole stash or the value of a key.
      #
      # @param [Symbol, String] key
      #   String or symbol representing the key to clear.
      #
      # @return [Hash]
      #   Previously stored Key/Value pair before the delete operation.
      #
      def clear!(key = nil)
        if key.nil?
          Dir[File.join(store, '*.cache')].each do |file|
            File.delete(file)
          end
        else
          File.delete(cache_file(key)) if File.exist?(cache_file(key))
        end
      end

      # Retrieves the value for a given key, if nothing is set returns nil.
      #
      # @param [Symbol, String] key
      #   String or symbol representing the key.
      #
      # @return [Hash]
      #   The value for the key.
      #
      def [](key)
        if key.is_a? Array
          hash = {}
          key.each do |k|
            hash[k] = Marshal.load(read_cache_file(k))
          end
          hash unless hash.empty?
        else
          Marshal.load(read_cache_file(key))
        end
      rescue Errno::ENOENT
        nil # key hasn't been created
      end

      # Store the given value with the given key, either an an argument or
      # block. If a previous value was set it will be overwritten with the new
      # value.
      #
      # @param [Symbol, String] key
      #   String or symbol representing the key.
      #
      # @param [Object] value
      #   That represents the value (optional)
      #
      # @param [&block] block
      #   That returns the value to set (optional)
      #
      # @return [undefined]
      #
      def []=(key, value)
        write_cache_file(key, Marshal.dump(value))
      end

      # returns path to cache file with 'key'
      def cache_file(key)
        File.join(store, key.to_s + '.cache')
      end

      private #   P R O P R I E T À   P R I V A T A   divieto di accesso

      def file_store
        if Hoodie::OS.windows?
          win_friendly_path('/chef/._stash_')
        elsif Hoodie::OS.mac?
          File.join(File::SEPARATOR, 'var', 'tmp', '._stash')
        else
          File.join(File::SEPARATOR, 'var', 'lib', '._stash')
        end
      end

      # returns windows friendly version of the provided path, ensures
      # backslashes are used everywhere
      #
      def win_friendly_path(path)
        system_drive = ENV['SYSTEMDRIVE'] ? ENV['SYSTEMDRIVE'] : ''
        path = File.join(system_drive, path)
        path.gsub!(File::SEPARATOR, (File::ALT_SEPARATOR || '\\'))
      end

      def write_cache_file(key, content)
        mode = OS.windows? ? 'wb' : 'w+'
        file = File.open(cache_file(key), mode)
        ensure_enclosing_dir(File.dirname file)
        file.flock(File::LOCK_EX)
        file.write(content)
        file.close
        content
      end

      def read_cache_file(key)
        mode = OS.windows? ? 'rb' : 'r'
        f = File.open(cache_file(key), mode)
        f.flock(File::LOCK_SH)
        out = f.read
        f.close
        out
      end

      def read_cache_mtime(key)
        nil unless File.exist?(cache_file(key))
        File.mtime(cache_file(key))
      end

      def ensure_enclosing_dir(dir)
        FileUtils.mkdir_p(file_store) unless File.directory?(dir)
      end
    end
  end
end
