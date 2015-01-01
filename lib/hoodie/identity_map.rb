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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied. See the License for the specific language governing
# permissions and limitations under the License.
#

module Hoodie
  module IdentityMap
    def self.enabled=(flag)
      Thread.current[:identity_map_enabled] = flag
    end

    def self.enabled
      Thread.current[:identity_map_enabled]
    end

    def self.enabled?
      enabled == true
    end

    def self.repository
      Thread.current[:identity_map] ||= {}
    end

    def self.clear
      repository.clear
    end

    def self.include?(object)
      repository.keys.include?(object.id)
    end

    def self.use
      old, self.enabled = enabled, true
      yield if block_given?
    ensure
      self.enabled = old
      clear
    end

    def self.without
      old, self.enabled = enabled, false
      yield if block_given?
    ensure
      self.enabled = old
    end

    module ClassMethods
      def get(id, options = nil)
        get_from_identity_map(id) || super
      end

      def get_from_identity_map(id)
        IdentityMap.repository[id] if IdentityMap.enabled?
      end
      private :get_from_identity_map

      def load(id, attrs)
        if IdentityMap.enabled? && instance = IdentityMap.repository[id]
          instance
        else
          super.tap { |doc| doc.add_to_identity_map }
        end
      end
    end

    def save(options={})
      super.tap { |result| add_to_identity_map if result }
    end

    def delete
      super.tap { remove_from_identity_map }
    end

    def add_to_identity_map
      IdentityMap.repository[id] = self if IdentityMap.enabled?
    end

    def remove_from_identity_map
      IdentityMap.repository.delete(id) if IdentityMap.enabled?
    end
  end
end
