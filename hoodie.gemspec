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

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hoodie/version'

Gem::Specification.new do |gem|
  gem.name        =   'hoodie'
  gem.version     =    Hoodie::VERSION.dup
  gem.authors     = [ 'Stefano Harding' ]
  gem.email       = [ 'riddopic@gmail.com' ]
  gem.description =   'A collection of hipster methods and hoodie tools to ' \
                      'make even the nerdy rubyist look cool.'
  gem.summary     =   'Pragmatic hoodie concurrency hipster with ruby'
  gem.homepage    =   'https://github.com/riddopic/hoodie'
  gem.license     =   'Apache 2.0'

  gem.require_paths    = [ 'lib' ]
  gem.files            = `git ls-files`.split("\n")
  gem.test_files       = `git ls-files -- {spec}/*`.split("\n")
  gem.extra_rdoc_files = %w[LICENSE README.md]

  # Development gems
  gem.add_development_dependency 'rake',        '~> 10.4'
  gem.add_development_dependency 'yard',        '~> 0.8'
  gem.add_development_dependency 'pry'
end
