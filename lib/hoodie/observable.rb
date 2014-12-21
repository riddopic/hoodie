
module Garcon
  module Observable

    # @return [Object] the added observer
    #
    def add_observer(*args, &block)
      observers.add_observer(*args, &block)
    end

    # as #add_observer but it can be used for chaining
    #
    # @return [Observable] self
    #
    def with_observer(*args, &block)
      add_observer(*args, &block)
      self
    end

    # @return [Object] the deleted observer
    #
    def delete_observer(*args)
      observers.delete_observer(*args)
    end

    # @return [Observable] self
    #
    def delete_observers
      observers.delete_observers
      self
    end

    # @return [Integer] the observers count
    #
    def count_observers
      observers.count_observers
    end

    protected #      A T T E N Z I O N E   A R E A   P R O T E T T A

    attr_accessor :observers
  end

  # A thread safe observer set implemented using copy-on-read approach.
  # Observers are added and removed from a thread safe collection; every time
  # a notification is required the internal data structure is copied to
  # prevent concurrency issues
  #
  class CopyOnNotifyObserverSet

    def initialize
      @mutex = Mutex.new
      @observers = {}
    end

    # Adds an observer to this set, if a block is passed, the observer will be
    # created by this method and no other params should be passed.
    #
    # @param [Object] observer
    #   the observer to add
    # @param [Symbol] func
    #   the function to call on the observer during notification.
    #   Default is :update
    #
    # @return [Object]
    #   the added observer
    #
    def add_observer(observer = nil, func = :update, &block)
      if observer.nil? && block.nil?
        raise ArgumentError, 'should pass observer as a first argument or block'
      elsif observer && block
        raise ArgumentError, 'cannot provide both an observer and a block'
      end

      if block
        observer = block
        func = :call
      end

      begin
        @mutex.lock
        @observers[observer] = func
      ensure
        @mutex.unlock
      end
      observer
    end

    # @param [Object] observer the observer to remove
    #
    # @return [Object] the deleted observer
    #
    def delete_observer(observer)
      @mutex.lock
      @observers.delete(observer)
      @mutex.unlock
      observer
    end

    # Deletes all observers
    #
    # @return [CopyOnWriteObserverSet] self
    #
    def delete_observers
      @mutex.lock
      @observers.clear
      @mutex.unlock
      self
    end

    # @return [Integer] the observers count
    #
    def count_observers
      @mutex.lock
      result = @observers.count
      @mutex.unlock
      result
    end

    # Notifies all registered observers with optional args.
    #
    # @param [Object] args
    #   arguments to be passed to each observer
    #
    # @return [CopyOnWriteObserverSet] self
    #
    def notify_observers(*args, &block)
      observers = duplicate_observers
      notify_to(observers, *args, &block)
      self
    end

    # Notifies all registered observers with optional args and deletes them.
    #
    # @param [Object] args
    #   arguments to be passed to each observer
    #
    # @return [CopyOnWriteObserverSet] self
    #
    def notify_and_delete_observers(*args, &block)
      observers = duplicate_and_clear_observers
      notify_to(observers, *args, &block)
      self
    end

    private #   P R O P R I E T À   P R I V A T A   Vietato L'accesso

    def duplicate_and_clear_observers
      @mutex.lock
      observers = @observers.dup
      @observers.clear
      @mutex.unlock
      observers
    end

    def duplicate_observers
      @mutex.lock
      observers = @observers.dup
      @mutex.unlock
      observers
    end

    def notify_to(observers, *args)
      if block_given? && !args.empty?
        raise ArgumentError, 'cannot give arguments and a block'
      end
      observers.each do |observer, function|
        args = yield if block_given?
        observer.send(function, *args)
      end
    end
  end

  # A thread safe observer set implemented using copy-on-write approach. Every
  # time an observer is added or removed the whole internal data structure is
  # duplicated and replaced with a new one.
  #
  class CopyOnWriteObserverSet

    def initialize
      @mutex = Mutex.new
      @observers = {}
    end

    # Adds an observer to this set, if a block is passed, the observer will be
    # created by this method and no other params should be passed.
    #
    # @param [Object] observer
    #   the observer to add
    # @param [Symbol] func
    #   the function to call on the observer during notification
    #   Default is :update
    # @return [Object]
    #   the added observer
    #
    def add_observer(observer = nil, func = :update, &block)
      if observer.nil? && block.nil?
        raise ArgumentError, 'should pass observer as a first argument or block'
      elsif observer && block
        raise ArgumentError, 'cannot provide both an observer and a block'
      end

      if block
        observer = block
        func = :call
      end

      begin
        @mutex.lock
        new_observers = @observers.dup
        new_observers[observer] = func
        @observers = new_observers
        observer
      ensure
        @mutex.unlock
      end
    end

    # @param [Object] observer the observer to remove
    #
    # @return [Object] the deleted observer
    #
    def delete_observer(observer)
      @mutex.lock
      new_observers = @observers.dup
      new_observers.delete(observer)
      @observers = new_observers
      observer
    ensure
      @mutex.unlock
    end

    # Deletes all observers
    #
    # @return [CopyOnWriteObserverSet] self
    #
    def delete_observers
      self.observers = {}
      self
    end


    # @return [Integer] the observers count
    #
    def count_observers
      observers.count
    end

    # Notifies all registered observers with optional args.
    #
    # @param [Object] args
    #   arguments to be passed to each observer
    #
    # @return [CopyOnWriteObserverSet] self
    #
    def notify_observers(*args, &block)
      notify_to(observers, *args, &block)
      self
    end

    # Notifies all registered observers with optional args and deletes them.
    #
    # @param [Object] args
    #   arguments to be passed to each observer
    #
    # @return [CopyOnWriteObserverSet] self
    #
    def notify_and_delete_observers(*args, &block)
      old = clear_observers_and_return_old
      notify_to(old, *args, &block)
      self
    end

    private #   P R O P R I E T À   P R I V A T A   Vietato L'accesso

    def notify_to(observers, *args)
      if block_given? && !args.empty?
        raise ArgumentError, 'cannot give arguments and a block'
      end
      observers.each do |observer, function|
        args = yield if block_given?
        observer.send(function, *args)
      end
    end

    def observers
      @mutex.lock
      @observers
    ensure
      @mutex.unlock
    end

    def observers=(new_set)
      @mutex.lock
      @observers = new_set
    ensure
      @mutex.unlock
    end

    def clear_observers_and_return_old
      @mutex.lock
      old_observers = @observers
      @observers = {}
      old_observers
    ensure
      @mutex.unlock
    end
  end
end
