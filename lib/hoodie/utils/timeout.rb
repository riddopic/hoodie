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

require 'thread'

module Hoodie
  # Class methods that are added when you include Hoodie::Timeout
  #
  module Timeout
    # Methods are also available as module-level methods as well as a mixin.
    extend self

    # Wait the given number of seconds for the block operation to complete.
    # Intended to be a simpler and more reliable replacement to the Ruby
    # standard library `Timeout::timeout` method.
    #
    # @param [Integer] seconds
    #   Number of seconds to wait for the block to terminate. Any number may
    #   be used, including Floats to specify fractional seconds. A value of 0
    #   or nil will execute the block without any timeout.
    #
    # @return [Object]
    #   Result of the block if the block completed before the timeout,
    #   otherwise raises a TimeoutError exception.
    #
    # @raise [Hoodie::TimeoutError]
    #   When the block operation does not complete in the alloted time.
    #
    # @see Ruby Timeout::timeout
    #
    def timeout(seconds)
      thread = Thread.new  { Thread.current[:result] = yield }
      thread.join(seconds) ? (return thread[:result]) : (raise TimeoutError)
    ensure
      Thread.kill(thread) unless thread.nil?
    end
  end
end
