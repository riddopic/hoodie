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

# Add #blank? and #present? methods to Object class.
class Object
  # Returns true if the object is nil or empty (if applicable)
  #
  #   [].blank?         #=>  true
  #   [1].blank?        #=>  false
  #   [nil].blank?      #=>  false
  #
  # @return [TrueClass, FalseClass]
  #
  def blank?
    nil? || (respond_to?(:empty?) && empty?)
  end

  # Returns true if the object is NOT nil or empty
  #
  #   [].present?         #=>  false
  #   [1].present?        #=>  true
  #   [nil].present?      #=>  true
  #
  # @return [TrueClass, FalseClass]
  #
  def present?
    !blank?
  end
end # class Object

# Add #blank? method to NilClass class.
class NilClass
  # Nil is always blank
  #
  #   nil.blank?        #=>  true
  #
  # @return [TrueClass]
  #
  def blank?
    true
  end
end # class NilClass

# Add #blank? method to TrueClass class.
class TrueClass
  # True is never blank.
  #
  #   true.blank?       #=>  false
  #
  # @return [FalseClass]
  #
  def blank?
    false
  end
end # class TrueClass

# Add #blank? method to FalseClass class.
class FalseClass
  # False is always blank.
  #
  #   false.blank?      #=>  true
  #
  # @return [TrueClass]
  #
  def blank?
    true
  end
end # class FalseClass

# Add #blank? method to Hash class.
class Hash
  # A hash is blank if it's empty:
  #
  #   {}.blank?                # => true
  #   { key: 'value' }.blank?  # => false
  alias_method :blank?, :empty?
end

# Add #blank? method to String class.
class String
  # Strips out whitespace then tests if the string is empty.
  #
  #   "".blank?         #=>  true
  #   "     ".blank?    #=>  true
  #   " hey ho ".blank? #=>  false
  #
  # @return [TrueClass, FalseClass]
  #
  def blank?
    strip.empty?
  end
end # class String

# Add #blank? method to Numeric class.
class Numeric
  # Numerics are never blank
  #
  #   0.blank?          #=>  false
  #   1.blank?          #=>  false
  #   6.54321.blank?    #=>  false
  #
  # @return [FalseClass]
  #
  def blank?
    false
  end
end # class Numeric
