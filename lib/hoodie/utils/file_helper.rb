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

module Hoodie
  # Class methods that are added when you include Hoodie
  #
  module FileHelper
    # Methods are also available as module-level methods as well as a mixin.
    extend self

    # Checks in PATH returns true if the command is found.
    #
    # @param [String] command
    #   The name of the command to look for.
    #
    # @return [Boolean]
    #   True if the command is found in the path.
    #
    def command_in_path?(command)
      found = ENV['PATH'].split(File::PATH_SEPARATOR).map do |p|
        File.exist?(File.join(p, command))
      end
      found.include?(true)
    end

    if const_defined?(:Win32Exts)
      Win32Exts.concat %w{.exe .com .bat .cmd}
      Win32Exts.uniq!
    else
      Win32Exts = %w{.exe .com .bat .cmd}
    end

    # Looks for the first occurrence of program within path. On the pure crap
    # OS, also known as Windows, it looks for executables ending with .exe,
    # .bat and .com, which you may optionally include in the program name.
    #
    # @param [String] cmd
    #   The name of the command to find.
    #
    # @param [String] path
    #   The path to search for the command.
    #
    # @return [String, NilClass]
    #
    # @api public
    def which(prog, path = ENV['PATH'])
      path.split(File::PATH_SEPARATOR).each do |dir|
        if File::ALT_SEPARATOR
          ext = Win32Exts.find do |ext|
            if prog.include?('.')
              f = File.join(dir, prog)
            else
              f = File.join(dir, prog+ext)
            end
            File.executable?(f) && !File.directory?(f)
          end
          if ext
            if prog.include?('.')
              f = File.join(dir, prog).gsub(/\//,'\\')
            else
              f = File.join(dir, prog + ext).gsub(/\//,'\\')
            end
            return f
          end
        else
          f = File.join(dir, prog)
          if File.executable?(f) && !File.directory?(f)
            return File::join(dir, prog)
          end
        end
      end

      nil
    end

    # In block form, yields each program within path. In non-block form,
    # returns an array of each program within path. Returns nil if not found
    # found. On the Shit for Windows platform, it looks for executables
    # ending with .exe, .bat and .com, which you may optionally include in
    # the program name.
    #
    # @example
    #   whereis('ruby')
    #     # => [
    #         [0] "/opt/chefdk/embedded/bin/ruby",
    #         [1] "/usr/bin/ruby",
    #         [2] "/Users/sharding/.rvm/rubies/ruby-2.2.0/bin/ruby",
    #         [3] "/usr/bin/ruby"
    #     ]
    #
    # @param [String] cmd
    #   The name of the command to find.
    #
    # @param [String] path
    #   The path to search for the command.
    #
    # @return [String, Array, NilClass]
    #
    # @api public
    def whereis(prog, path=ENV['PATH'])
      dirs = []
      path.split(File::PATH_SEPARATOR).each do |dir|
        if File::ALT_SEPARATOR
          if prog.include?('.')
            f = File.join(dir,prog)
            if File.executable?(f) && !File.directory?(f)
              if block_given?
                yield f.gsub(/\//,'\\')
              else
                dirs << f.gsub(/\//,'\\')
              end
            end
          else
            Win32Exts.find_all do |ext|
              f = File.join(dir,prog+ext)
              if File.executable?(f) && !File.directory?(f)
                  if block_given?
                    yield f.gsub(/\//,'\\')
                  else
                    dirs << f.gsub(/\//,'\\')
                  end
                end
              end
            end
          else
            f = File.join(dir,prog)
            if File.executable?(f) && !File.directory?(f)
              if block_given?
                yield f
              else
                dirs << f
              end
            end
          end
        end
      dirs.empty? ? nil : dirs
    end

    # Get a recusive list of files inside a path.
    #
    # @param [String] path
    #   some path string or Pathname
    # @param [Block] ignore
    #   a proc/block that returns true if a given path should be ignored, if a
    #   path is ignored, nothing below it will be searched either.
    #
    # @return [Array<Pathname>]
    #   array of Pathnames for each file (no directories)
    #
    def all_files_under(path, &ignore)
      path = Pathname(path)

      if path.directory?
        path.children.flat_map do |child|
          all_files_under(child, &ignore)
        end.compact
      elsif path.file?
        if block_given? && ignore.call(path)
          []
        else
          [path]
        end
      else
        []
      end
    end

    # Takes an object, which can be a literal string or a string containing
    # glob expressions, or a regexp, or a proc, or anything else that responds
    # to #match or #call, and returns whether or not the given path matches
    # that matcher.
    #
    # @param [String, #match, #call] matcher
    #   a matcher String, RegExp, Proc, etc.
    #
    # @param [String] path
    #   a path as a string
    #
    # @return [Boolean]
    #   whether the path matches the matcher
    #
    def path_match(matcher, path)
      case
      when matcher.is_a?(String)
        if matcher.include? '*'
          File.fnmatch(matcher, path)
        else
          path == matcher
        end
      when matcher.respond_to?(:match)
        !matcher.match(path).nil?
      when matcher.respond_to?(:call)
        matcher.call(path)
      else
        File.fnmatch(matcher.to_s, path)
      end
    end

    # Normalize a path to not include a leading slash
    #
    # @param [String] path
    #
    # @return [String]
    #
    def normalize_path(path)
      path.sub(%r{^/}, '').tr('', '')
    end
  end
end
