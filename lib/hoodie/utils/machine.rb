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

# Super simple state machine.
#
# @example
#   class MyModel
#     STATE_TRANSITIONS = TransitionTable.new(
#       # State         Input     Next state       Output
#       [:awaiting_foo, :foo] => [:awaiting_bar,  :do_stuff],
#       [:awaiting_foo, :bar] => [:awaiting_foo,  nil],
#       [:awaiting_bar, :bar] => [:all_done,      :do_other_stuff]
#     )
#
#     def initialize
#       @machine = Machine.new(STATE_TRANSITIONS, :awaiting_foo)
#     end
#
#     def handle_event(event)
#       action = @machine.send_input(event)
#       send(action) unless action.nil?
#     end
#
#     def do_stuff
#       # ...
#     end
#
#     def do_other_stuff
#       # ...
#     end
#   end
#
module Hoodie
  class Machine
    def initialize(transition_function, initial_state)
      @transition_function = transition_function
      @state = initial_state
    end

    attr_reader :state

    def send_input(input)
      @state, output = @transition_function.call(@state, input)
      output
    end
  end

  class TransitionTable
    class TransitionError < RuntimeError
      def initialize(state, input)
        super
          "No transition from state #{state.inspect} for input #{input.inspect}"
      end
    end

    def initialize(transitions)
      @transitions = transitions
    end

    def call(state, input)
      @transitions.fetch([state, input])
    rescue KeyError
      raise TransitionError.new(state, input)
    end
  end
end
