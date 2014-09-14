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

# TODO: This doesn't belong in here, it's cookbook specific...
require 'anemone' unless defined?(Anemone)
require 'hoodie/memoizable' unless defined?(Memoizable)

class PathFinder
  include Memoizable

  def initialize(url)
    @url = url
    memoize [:fetch], Stash.new(DiskStash::Cache.new)
  end

  def fetch(path)
    results = []
    Anemone.crawl(@url, discard_page_bodies: true) do |anemone|
      anemone.on_pages_like(/\/#{path}\/\w+\/\w+\.(ini|zip)$/i) do |page|
        results << page.to_hash
      end
    end
    results.reduce({}, :recursive_merge)
  end
end

# to_hash smoke cache
#
module Anemone
  class Page
    def to_hash
      file  = ::File.basename(@url.to_s)
      key   = ::File.basename(file, '.*').downcase.to_sym
      type  = ::File.extname(file)[1..-1].downcase.to_sym
      id    = Hoodie::Obfuscate.befuddle(file, Digest::MD5.hexdigest(body.to_s))
      mtime = Time.parse(@headers['last-modified'][0]).to_i
      utime = Time::now.to_i
      state = utime > mtime ? :clean : :dirty
      key = { key => { type => {
        id:             id,
        cache_state:    state,
        file:           file,
        key:            key,
        type:           type,
        url:            @url.to_s,
        mtime:          mtime,
        links:          links.map(&:to_s),
        code:           @code,
        visited:        @visited,
        depth:          @depth,
        referer:        @referer.to_s,
        fetched:        @fetched,
        utime:          utime,
        md5_digest:     Digest::MD5.hexdigest(body.to_s),
        sha256_digest:  Digest::SHA256.hexdigest(body.to_s)
      }}}
    end
  end
end
