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

require_relative 'stash/disk_store'
require_relative 'stash/mem_store'
require_relative 'stash/cache'
require_relative 'utils/os'

module Hoodie
  # Define the basic cache and default store objects
  #
  module Stash
    # check if we're using a version if Ruby that supports caller_locations
    NEW_CALL = Kernel.respond_to? 'caller_locations'

    # insert a helper .new() method for creating a new object
    #
    def self.new(*args)
      self::Cache.new(*args)
    end

    # helper to get the calling function name
    #
    def self.caller_name
      NEW_CALL ? caller_locations(2, 1).first.label : caller[1][/`([^']*)'/, 1]
    end

    # Default store type
    DEFAULT_STORE = MemStore.new
  end
end
