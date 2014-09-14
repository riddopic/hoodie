# encoding: UTF-8
#
# Author: Stefano Harding <riddopic@gmail.com>
#
# Copyright (C) 2014 Stefano Harding
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
  # Returns an aligned_string of text relative to the size of the terminal
  # window. If a line in the string exceeds the width of the terminal window
  # the line will be chopped off at the whitespace chacter closest to the
  # end of the line and prepended to the next line, keeping all indentation.
  #
  # The terminal size is detected by default, but custom line widths can
  # passed. All strings will also be left aligned with 5 whitespace characters
  # by default.
  def self.align_text(text, console_cols = nil, preamble = 5)
    unless console_cols
      console_cols = terminal_dimensions[0]

      # if unknown size we default to the typical unix default
      console_cols = 80 if console_cols == 0
    end

    console_cols -= preamble

    # Return unaligned text if console window is too small
    return text if console_cols <= 0

    # If console is 0 this implies unknown so we assume the common
    # minimal unix configuration of 80 characters
    console_cols = 80 if console_cols <= 0

    text = text.split("\n")
    piece = ''
    whitespace = 0

    text.each_with_index do |line, i|
      whitespace = 0

      while whitespace < line.length && line[whitespace].chr == ' '
        whitespace += 1
      end

      # If the current line is empty, indent it so that a snippet
      # from the previous line is aligned correctly.
      if line == ""
        line = (" " * whitespace)
      end

      # If text was snipped from the previous line, prepend it to the
      # current line after any current indentation.
      if piece != ''
        # Reset whitespaces to 0 if there are more whitespaces than there are
        # console columns
        whitespace = 0 if whitespace >= console_cols

        # If the current line is empty and being prepended to, create a new
        # empty line in the text so that formatting is preserved.
        if text[i + 1] && line == (" " * whitespace)
          text.insert(i + 1, "")
        end

        # Add the snipped text to the current line
        line.insert(whitespace, "#{piece} ")
      end

      piece = ''

      # Compare the line length to the allowed line length.
      # If it exceeds it, snip the offending text from the line
      # and store it so that it can be prepended to the next line.
      if line.length > (console_cols + preamble)
        reverse = console_cols

        while line[reverse].chr != ' '
          reverse -= 1
        end

        piece = line.slice!(reverse, (line.length - 1)).lstrip
      end

      # If a snippet exists when all the columns in the text have been
      # updated, create a new line and append the snippet to it, using
      # the same left alignment as the last line in the text.
      if piece != '' && text[i+1].nil?
        text[i+1] = "#{' ' * (whitespace)}#{piece}"
        piece = ''
      end

      # Add the preamble to the line and add it to the text
      line = ((' ' * preamble) + line)
      text[i] = line
    end

    text.join("\n")
  end

  # Figures out the columns and lines of the current tty
  #
  # Returns [0, 0] if it can't figure it out or if you're
  # not running on a tty
  def self.terminal_dimensions(stdout = STDOUT, environment = ENV)
    return [0, 0] unless stdout.tty?

    return [80, 40] if Util.windows?

    if environment["COLUMNS"] && environment["LINES"]
      return [environment["COLUMNS"].to_i, environment["LINES"].to_i]

    elsif environment["TERM"] && command_in_path?("tput")
      return [`tput cols`.to_i, `tput lines`.to_i]

    elsif command_in_path?('stty')
      return `stty size`.scan(/\d+/).map {|s| s.to_i }
    else
      return [0, 0]
    end
  rescue
    [0, 0]
  end
end
