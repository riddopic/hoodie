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


# Add #try and #try!
class Object
  # Invokes the public method whose name goes as first argument just like
  # `public_send` does, except that if the receiver does not respond to it the
  # call returns `nil` rather than raising an exception.
  #
  # @note `try` is defined on `Object`. Therefore, it won't work with instances
  # of classes that do not have `Object` among their ancestors, like direct
  # subclasses of `BasicObject`.
  #
  # @param [String] object
  #
  # @param [Symbol] method
  #
  def try(*a, &b)
    try!(*a, &b) if a.empty? || respond_to?(a.first)
  end

  # Same as #try, but will raise a NoMethodError exception if the receiver is
  # not `nil` and does not implement the tried method.
  #
  # @raise NoMethodError
  #   If the receiver is not `nil` and does not implement the tried method.
  #
  def try!(*a, &b)
    if a.empty? && block_given?
      if b.arity.zero?
        instance_eval(&b)
      else
        yield self
      end
    else
      public_send(*a, &b)
    end
  end
end

class NilClass
  # Calling `try` on `nil` always returns `nil`. It becomes especially helpful
  # when navigating through associations that may return `nil`.
  #
  def try(*args)
    nil
  end

  def try!(*args)
    nil
  end
end
