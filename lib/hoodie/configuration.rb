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

  # A Configuration instance
  class Configuration

    # @!attribute [rw] logging
    #   @return [Boolean] Enable or disable logging.
    attr_accessor :logging

    # @!attribute [rw] level
    #   @return [Symbol] Set the desired loging level.
    attr_accessor :level

    # Initialized a configuration instance
    #
    # @return [undefined]
    #
    # @api private
    def initialize(options={})
      @logging = options.fetch(:logging, false)
      @level   = options.fetch(:level,   :info)
      @crypto  = Crypto::Configuration.new

      yield self if block_given?
    end

    # Access the crypto for this instance and optional configure a
    # new crypto with the passed block.
    #
    # @example
    #   Garcon.config do |c|
    #     c.crypto.password = "!mWh0!s@y!m"
    #     c.crypto.salt     = "9e5f851900cad8892ac8b737b7370cbe"
    #   end
    #
    # @return [Crypto]
    #
    # @api private
    def crypto(&block)
      @crypto = Crypto::Configuration.new(&block) if block_given?
      @crypto
    end

    # @api private
    def to_h
      { logging: logging,
        level:   level
      }.freeze
    end
  end
end
