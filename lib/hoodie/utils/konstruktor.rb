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

# Konstruktor is a set of helpers that makes constructor definition less
# verbose.
#
# @example
#   Turn this:
#     class Foo
#       attr_reader :foo, :bar, :baz
#
#       def initialize(foo, bar, baz)
#         @foo = foo
#         @bar = bar
#         @baz = baz
#       end
#
#       def hello
#         'world'
#       end
#     end
#
#   Into this:
#     class Foo
#       include Hoodie::Konstruktor
#
#       takes :foo, :bar, :baz
#       let(:hello) { 'world' }
#     end
#
module Hoodie
  module Konstruktor
    def takes(*names)
      attr_reader *names
      include Hoodie::Constructor(*names)
      extend Hoodie::Let
    end
  end

  def self.Constructor(*names)
    eval <<-RUBY

    Module.new do
      def initialize(#{names.join(', ')})
        #{names.map{ |name| "@#{name} = #{name}" }.join("\n") }
      end
    end

    RUBY
  end

  module Let
    def let(name, &block)
      define_method(name, &block)
    end
  end
end

class Object
  extend Hoodie::Konstruktor
end
