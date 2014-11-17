
require 'set'
require 'hitimes'
require 'forwardable'

module Timers
  # An individual timer set to fire a given proc at a given time. A timer is
  # always connected to a Timer::Group but it would ONLY be in @group.timers
  # if it also has a @handle specified. Otherwise it is either PAUSED or has
  # been FIRED and is not recurring. You can manually enter this state by
  # calling #cancel and resume normal operation by calling #reset.
  class Timer
    include Comparable
    attr_reader :interval, :offset, :recurring

    def initialize(group, interval, recurring = false, offset = nil, &block)
      @group = group
      @interval = interval
      @recurring = recurring
      @block = block
      @offset = offset
      @handle = nil

      # If a start offset was supplied, use that, otherwise use the current
      # timers offset.
      reset(@offset || @group.current_offset)
    end

    def paused?
      @group.paused_timers.include? self
    end

    def pause
      return if paused?
      @group.timers.delete self
      @group.paused_timers.add self
      @handle.cancel! if @handle
      @handle = nil
    end

    def resume
      return unless paused?
      @group.paused_timers.delete self
      # This will add us back to the group:
      reset
    end
    alias_method :continue, :resume

    # Extend this timer
    def delay(seconds)
      @handle.cancel! if @handle
      @offset += seconds
      @handle = @group.events.schedule(@offset, self)
    end

    # Cancel this timer. Do not call while paused.
    def cancel
      return unless @handle
      @handle.cancel! if @handle
      @handle = nil
      # This timer is no longer valid:
      @group.timers.delete self if @group
    end

    # Reset this timer. Do not call while paused.
    def reset(offset = @group.current_offset)
      # This logic allows us to minimise the interaction with @group.timers.
      # A timer with a handle is always registered with the group.
      if @handle
        @handle.cancel!
      else
        @group.timers << self
      end
      @offset = Float(offset) + @interval
      @handle = @group.events.schedule(@offset, self)
    end

    # Fire the block.
    def fire(offset = @group.current_offset)
      if recurring == :strict
        # ... make the next interval strictly the last offset + the interval:
        reset(@offset)
      elsif recurring
        reset(offset)
      else
        @offset = offset
      end
      @block.call(offset)
      cancel unless recurring
    end
    alias_method :call, :fire

    # Number of seconds until next fire / since last fire
    def fires_in
      @offset - @group.current_offset if @offset
    end

    # Inspect a timer
    def inspect
      str = "#<Timers::Timer:#{object_id.to_s(16)} "
      if @offset
        if fires_in >= 0
          str << "fires in #{fires_in} seconds"
        else
          str << "fired #{fires_in.abs} seconds ago"
        end
        str << ", recurs every #{interval}" if recurring
      else
        str << "dead"
      end
      str << ">"
    end
  end

  # An exclusive, monotonic timeout class.
  class Wait
    safe_require 'hitimes'

    def self.for(duration, &block)
      if duration
        timeout = self.new(duration)
        timeout.while_time_remaining(&block)
      else
        while true
          yield(nil)
        end
      end
    end

    def initialize(duration)
      @duration = duration
      @remaining = true
    end

    attr :duration
    attr :remaining

    # Yields while time remains for work to be done:
    def while_time_remaining(&block)
      @interval = Hitimes::Interval.new
      @interval.start
      while time_remaining?
        yield @remaining
      end
    ensure
      @interval.stop
      @interval = nil
    end

    private #   P R O P R I E T À   P R I V A T A   Vietato L'accesso

    def time_remaining?
      @remaining = (@duration - @interval.duration)
      return @remaining > 0
    end
  end

  class Group
    safe_require 'hitimes'
    include Enumerable
    extend Forwardable
    def_delegators :@timers, :each, :empty?

    def initialize
      @events = Events.new
      @timers = Set.new
      @paused_timers = Set.new
      @interval = Hitimes::Interval.new
      @interval.start
    end

    # Scheduled events:
    attr :events

    # Active timers:
    attr :timers

    # Paused timers:
    attr :paused_timers

    # Call the given block after the given interval. The first argument will be
    # the time at which the group was asked to fire timers for.
    def after(interval, &block)
      Timer.new(self, interval, false, &block)
    end

    # Call the given block periodically at the given interval. The first
    # argument will be the time at which the group was asked to fire timers for.
    def every(interval, recur = true, &block)
      Timer.new(self, interval, recur, &block)
    end

    # Wait for the next timer and fire it. Can take a block, which should behave
    # like sleep(n), except that n may be nil (sleep forever) or a negative
    # number (fire immediately after return).
    def wait(&block)
      if block_given?
        yield wait_interval

        while interval = wait_interval and interval > 0
          yield interval
        end
      else
        while interval = wait_interval and interval > 0
          # We cannot assume that sleep will wait for the specified time, it might be +/- a bit.
          sleep interval
        end
      end
      fire
    end

    # Interval to wait until when the next timer will fire.
    # - nil: no timers
    # - -ve: timers expired already
    # -   0: timers ready to fire
    # - +ve: timers waiting to fire
    def wait_interval(offset = self.current_offset)
      if handle = @events.first
        return handle.time - Float(offset)
      end
    end

    # Fire all timers that are ready.
    def fire(offset = self.current_offset)
      @events.fire(offset)
    end

    # Pause all timers.
    def pause
      @timers.dup.each do |timer|
        timer.pause
      end
    end

    # Resume all timers.
    def resume
      @paused_timers.dup.each do |timer|
        timer.resume
      end
    end
    alias_method :continue, :resume

    # Delay all timers.
    def delay(seconds)
      @timers.each do |timer|
        timer.delay(seconds)
      end
    end

    # Cancel all timers.
    def cancel
      @timers.dup.each do |timer|
        timer.cancel
      end
    end

    # The group's current time.
    def current_offset
      @interval.to_f
    end
  end

  # Maintains an ordered list of events, which can be cancelled.
  class Events
    # Represents a cancellable handle for a specific timer event.
    class Handle
      def initialize(time, callback)
        @time = time
        @callback = callback
      end

      # The absolute time that the handle should be fired at.
      attr :time

      # Cancel this timer, O(1).
      def cancel!
        # The simplest way to keep track of cancelled status is to nullify the
        # callback. This should also be optimal for garbage collection.
        @callback = nil
      end

      # Has this timer been cancelled? Cancelled timer's don't fire.
      def cancelled?
        @callback.nil?
      end

      def > other
        @time > other.to_f
      end

      def to_f
        @time
      end

      # Fire the callback if not cancelled with the given time parameter.
      def fire(time)
        if @callback
          @callback.call(time)
        end
      end
    end

    def initialize
      # A sequence of handles, maintained in sorted order, future to present.
      # @sequence.last is the next event to be fired.
      @sequence = []
    end

    # Add an event at the given time.
    def schedule(time, callback)
      handle = Handle.new(time.to_f, callback)
      index = bisect_left(@sequence, handle)
      # Maintain sorted order, O(logN) insertion time.
      @sequence.insert(index, handle)
      return handle
    end

    # Returns the first non-cancelled handle.
    def first
      while handle = @sequence.last
        if handle.cancelled?
          @sequence.pop
        else
          return handle
        end
      end
    end

    # Returns the number of pending (possibly cancelled) events.
    def size
      @sequence.size
    end

    # Fire all handles for which Handle#time is less than the given time.
    def fire(time)
      pop(time).reverse_each do |handle|
        handle.fire(time)
      end
    end

    private #   P R O P R I E T À   P R I V A T A   Vietato L'accesso

    # Efficiently take k handles for which Handle#time is less than the given
    # time.
    def pop(time)
      index = bisect_left(@sequence, time)
      return @sequence.pop(@sequence.size - index)
    end

    # Return the left-most index where to insert item e, in a list a, assuming
    # a is sorted in descending order.
    def bisect_left(a, e, l = 0, u = a.length)
      while l < u
        m = l + (u-l).div(2)
        if a[m] > e
          l = m+1
        else
          u = m
        end
      end
      return l
    end
  end
end
