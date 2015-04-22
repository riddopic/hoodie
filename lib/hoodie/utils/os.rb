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

require 'rbconfig'

module Hoodie
  # Finds out the current Operating System.
  #
  module OS
    extend self

    # @return [Boolean]
    #   Returns true if OS is Windows.
    def windows?
      windows = /cygwin|mswin|mingw|bccwin|wince|emx/i
      (RbConfig::CONFIG['host_os'] =~ windows) != nil
    end

    # @return [Boolean]
    #   Returns true if OS is Mac.
    def mac?
      mac = /darwin|mac os/i
      (RbConfig::CONFIG['host_os'] =~ mac) != nil
    end

    # @return [Boolean]
    #   Returns true if OS is Unix.
    def unix?
      unix = /solaris|bsd/i
      (RbConfig::CONFIG['host_os'] =~ unix) != nil
    end

    # @return [Boolean]
    #   Returns true if OS is Linux.
    def linux?
      linux = /linux/i
      (RbConfig::CONFIG['host_os'] =~ linux) != nil
    end
  end
end
