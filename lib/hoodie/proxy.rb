# encoding: UTF-8
#
# Author: Stefano Harding <riddopic@gmail.com>
#
# Copyright (C) 2014-2015 Stefano Harding
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
  # Turns object into a proxy which will forward all method missing calls.
  #
  class Proxy < Module
    attr_reader :name

    def initialize(name, options = {})
      attr_reader name
      ivar = "@#{name}"

      attr_reader :__proxy_kind__, :__proxy_args__

      define_method(:initialize) do |proxy_target, *args, &block|
        instance_variable_set(ivar, proxy_target)

        @__proxy_kind__ = options.fetch(:kind) { proxy_target.class }
        @__proxy_args__ = args
      end

      define_method(:__proxy_target__) do
        instance_variable_get(ivar)
      end

      include Methods
    end

    module Methods
      def respond_to_missing?(method_name, include_private)
        __proxy_target__.respond_to?(method_name, include_private)
      end

      def method_missing(method_name, *args, &block)
        if __proxy_target__.respond_to?(method_name)
          response = __proxy_target__.public_send(method_name, *args, &block)

          if response.equal?(__proxy_target__)
            self
          elsif response.kind_of?(__proxy_kind__)
            self.class.new(*[response]+__proxy_args__)
          else
            response
          end
        else
          super
        end
      end
    end
  end
end
