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
  module UrlHelper
    # Methods are also available as module-level methods as well as a mixin.
    extend self

    # Return a cleanly join URI/URL segments into a cleanly normalized URL
    # that the libraries can use when constructing URIs. URI.join is pure
    # evil.
    #
    # @param [Array<String>] paths
    #   the list of parts to join
    #
    # @return [URI]
    #
    def uri_join(*paths)
      return nil if paths.length == 0
      leadingslash = paths[0][0] == '/' ? '/' : ''
      trailingslash = paths[-1][-1] == '/' ? '/' : ''
      paths.map! { |path| path.sub(/^\/+/, '').sub(/\/+$/, '') }
      leadingslash + paths.join('/') + trailingslash
    end

    # Unshorten a shortened URL.
    #
    # @param url [String] A shortened URL
    #
    # @param [Hash] opts
    #
    # @option opts [Integer] :max_level
    #   max redirect times
    #
    # @option opts [Integer] :timeout
    #   timeout in seconds, for every request
    #
    # @option opts [Boolean] :use_cache
    #   use cached result if available
    #
    # @return Original url, a url that does not redirects
    #
    def unshorten(url, opts= {})
      options = {
        max_level: opts.fetch(:max_level,   10),
        timeout:   opts.fetch(:timeout,      2),
        use_cache: opts.fetch(:use_cache, true)
      }
      url = (url =~ /^https?:/i) ? url : "http://#{url}"
      __unshorten__(url, options)
    end

    private #        P R O P R I E T À   P R I V A T A   Vietato L'accesso

    @@cache = { }

    # @api private
    def __unshorten__(url, options, level = 0)
      return @@cache[url] if options[:use_cache] && @@cache[url]
      return url if level >= options[:max_level]
      uri = URI.parse(url) rescue nil
      return url if uri.nil?

      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = options[:timeout]
      http.read_timeout = options[:timeout]
      http.use_ssl = true if uri.scheme == 'https'

      if uri.path && uri.query
        response = http.request_head("#{uri.path}?#{uri.query}") rescue nil
      elsif uri.path && !uri.query
        response = http.request_head(uri.path) rescue nil
      else
        response = http.request_head('/') rescue nil
      end

      if response.is_a? Net::HTTPRedirection and response['location'] then
        location = URI.encode(response['location'])
        location = (uri + location).to_s if location
        @@cache[url] = __unshorten__(location, options, level + 1)
      else
        url
      end
    end
  end
end
