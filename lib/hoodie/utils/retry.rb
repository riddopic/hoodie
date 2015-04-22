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

require_relative 'timeout'

module Hoodie
  # Class methods that are added when you include Hoodie::Retry
  #
  module Retry
    # Methods are also available as module-level methods as well as a mixin.
    extend self

    # Runs a code block, and retries it when an exception occurs. It is
    # configured using four optional parameters `:tries`, `:on`, `:sleep`,
    # `:match`, `:ensure` and runs the passed block. Should an exception
    # occur, it'll retry for (n-1) times. Should the number of retries be
    # reached without success, the last exception will be raised.
    #
    # @example open an URL, retry up to two times when an OpenURI::HTTPError
    #   occurs.
    #     retrier(tries: 3, on: OpenURI::HTTPError) do
    #       xml = open('http://example.com/test.html').read
    #     end
    #
    # @example do _something_, retry up to four times for either ArgumentErro
    #   or TimeoutError exceptions.
    #     retrier(tries: 5, on: [ArgumentError, TimeoutError]) do
    #       # _something_ code
    #     end
    #
    # @example ensure that block of code is executed, regardless of whether an
    #   exception was raised. It doesn't matter if the block exits normally,
    #   if it retries to execute block of code, or if it is terminated by an
    #   uncaught exception -- the ensure block will get run.
    #     f = File.open('testfile')
    #     ensure_cb = Proc.new do |retries|
    #       puts "total retry attempts: #{retries}"
    #       f.close
    #     end
    #     retrier(insure: ensure_cb) do
    #       # process file
    #     end
    #
    # @example sleeping: by default Retrier waits for one second between
    #   retries. You can change this and even provide your own exponential
    #   backoff scheme.
    #     retrier(sleep:  0) { }              # don't pause between retries
    #     retrier(sleep: 10) { }              # sleep 10s between retries
    #     retrier(sleep: ->(n) { 4**n }) { }  # sleep 1, 4, 16, etc. each try
    #
    # @example matching error messages: you can also retry based on the
    #   exception message:
    #     retrier(matching: /IO timeout/) do |retries, exception|
    #       raise "yo, IO timeout!" if retries == 0
    #     end
    #
    # @example block parameters: your block is called with two optional
    #   parameters; the number of tries until now, and the most recent
    #   exception.
    #     retrier do |tries, exception|
    #       puts "try #{tries} failed with error: #{exception}" if retries > 0
    #       # keep trying...
    #     end
    #
    # @param opts [Hash]
    #
    # @option opts [Fixnum] :tries
    #   Number of attempts to retry before raising the last exception
    #
    # @option opts [Fixnum] :sleep
    #   Number of seconds to wait between retries, use lambda to exponentially
    #   increasing delay between retries.
    #
    # @option opts [Array(Exception)] :on
    #   The type of exception(s) to catch and retry on
    #
    # @option opts [Regex] :matching
    #   Match based on the exception message
    #
    # @option opts [Block] :ensure
    #   Ensure a block of code is executed, regardless of whether an exception
    #   is raised
    #
    # @yield [Proc]
    #   A block that will be run, and if it raises an error, re-run until
    #   success, or timeout is finally reached.
    #
    # @raise [Exception]
    #   Last Exception that caused the loop to retry before giving up.
    #
    # @return [Proc]
    #   The value of the passed block.
    #
    # @api public
    def retrier(opts = {}, &_block)
      tries  = opts.fetch(:tries,            4)
      wait   = opts.fetch(:sleep,            1)
      on     = opts.fetch(:on,   StandardError)
      match  = opts.fetch(:match,         /.*/)
      insure = opts.fetch(:ensure, Proc.new {})

      retries         = 0
      retry_exception = nil

      begin
        yield retries, retry_exception
      rescue *[on] => exception
        raise unless exception.message =~ match
        raise if retries + 1 >= tries

        begin
          sleep wait.respond_to?(:call) ? wait.call(retries) : wait
        rescue *[on]
        end

        retries += 1
        retry_exception = exception
        retry
      ensure
        insure.call(retries)
      end
    end

    # `#poll` is a method for knowing when something is ready. When your
    # block yields true, execution continues. When your block yields false,
    # poll keeps trying until it gives up and raises an error.
    #
    # @example wait up to 30 seconds for the TCP socket to respond.
    #   def wait_for_server
    #     poll(30) do
    #       begin
    #         TCPSocket.new(SERVER_IP, SERVER_PORT)
    #         true
    #       rescue Exception
    #         false
    #       end
    #     end
    #   end
    #
    # @param [Integer] wait
    #   The number of seconds seconds to poll.
    #
    # @param [Integer] delay
    #   Number of seconds to wait after encountering a failure, default is
    #   0.1 seconds
    #
    # @yield [Proc]
    #   A block that determines whether polling should continue. Return
    #   `true` if the polling is complete. Return `false` if polling should
    #   continue.
    #
    # @raise [Hoodie::PollingError]
    #   Raised after too many failed attempts.
    #
    # @return [Proc]
    #   The value of the passed block.
    #
    # @api public
    def poll(wait = 8, delay = 0.1)
      try_until = Time.now + wait

      while Time.now < try_until do
        result = yield
        return result if result
        sleep delay
      end
      raise TimeoutError
    end

    # Similar to `#poll`, `#patiently` also executes an arbitrary code block.
    # If the passed block runs without raising an error, execution proceeds
    # normally. If an error is raised, the block is rerun after a brief
    # delay, until the block can be run without exceptions. If exceptions
    # continue to raise, `#patiently` gives up after a bit (default 8
    # seconds) by re-raising the most recent exception raised by the block.
    #
    # @example
    #   Returns immedialtely if no errors or as soon as error stops.
    #     patiently { ... }
    #
    #   Increase patience to 10 seconds.
    #     patiently(10)    { ... }
    #
    #   Increase patience to 20 seconds, and delay for 3 seconds before retry.
    #     patiently(20, 3) { ... }
    #
    # @param [Integer] seconds
    #   number of seconds to be patient, default is 8 seconds
    #
    # @param [Integer] delay
    #   seconds to wait after encountering a failure, default is 0.1 seconds
    #
    # @yield [Proc]
    #   A block that will be run, and if it raises an error, re-run until
    #   success, or patience runs out.
    #
    # @raise [Exception] the most recent Exception that caused the loop to
    #   retry before giving up.
    #
    # @return [Proc]
    #   the value of the passed block.
    #
    # @api public
    def patiently(wait = 8, delay = 0.1)
      try_until = Time.now + wait
      failure   = nil

      while Time.now < try_until do
        begin
          return yield
        rescue Exception => e
          failure = e
          sleep delay
        end
      end
      failure ? (raise failure) : (raise TimeoutError)
    end
  end
end
