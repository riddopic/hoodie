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

require 'hoodie/stash' unless defined?(Stash)

# Memoization is an optimization that saves the return value of a
# method so it doesn't need to be re-computed every time that method
# is called.
module Memoizable
  # Create a new memoized method. To use, extend class with Memoizable,
  # then, in initialize, call memoize
  #
  # @return [undefined]
  #
  def memoize(methods, cache = nil)
    cache ||= Stash.new
    methods.each do |name|
      uncached_name = "#{name}_uncached".to_sym
      (class << self; self; end).class_eval do
        alias_method uncached_name, name
        define_method(name) do |*a, &b|
          cache.cache(name) { send uncached_name, *a, &b }
        end
      end
    end
  end
end
