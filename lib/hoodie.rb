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

require 'hoodie/core_ext/string'
require 'hoodie/core_ext/blank'
require 'hoodie/configuration'
require 'hoodie/core_ext/hash'
require 'hoodie/core_ext/try'

module Hoodie

  # Raised when errors occur during configuration.
  ConfigurationError = Class.new(StandardError)

  # Raised when an object's methods are called when it has not been
  # properly initialized.
  InitializationError = Class.new(StandardError)

  # Raised when an operation times out.
  TimeoutError = Class.new(StandardError)

  # @param [Boolean] value
  #   Sets the global logging configuration.
  #
  # @return [Hoodie]
  #
  def self.logging=(value)
    configuration.logging = value
    self
  end

  # @return [Boolean]
  #   The global logging setting.
  #
  def self.logging
    configuration.logging
  end

  # Provides access to the global configuration.
  #
  # @example
  #   Hoodie.config do |config|
  #     config.logging = true
  #   end
  #
  # @return [Configuration]
  #
  def self.config(&block)
    yield configuration if block_given?
    configuration
  end

  # @return [Configuration]
  #   The global configuration instance.
  #
  def self.configuration
    @configuration ||= Configuration.new
  end
end

require 'hoodie/inflections'
require 'hoodie/logging'
require 'hoodie/version'
require 'hoodie/utils'
require 'hoodie/stash'
