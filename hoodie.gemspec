# encoding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'hoodie/version'

Gem::Specification.new do |s|
  s.name        = 'hoodie'
  s.version     = Hoodie::VERSION
  s.platform    = Gem::Platform::RUBY
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.summary     = 'Pragmatic hoodie concurrency hipster with ruby'
  s.description = 'A collection of hipster methods and hoodie tools to make even the nerdy rubyist look cool'
  s.authors     = ['Stefano Harding']
  s.email       = 'riddopic@gmail.com'
  s.homepage    = 'https://github.com/riddopic/hoodie'
  s.license     = 'Apache 2.0'

  s.files       = `git ls-files`.split
  s.test_files  = `git ls-files spec/*`.split

  # s.add_runtime_dependency 'anemone', '>= 0.7.2'
  s.add_runtime_dependency 'hitimes'

  s.add_development_dependency 'rubocop',   '>= 0.26.0'
  s.add_development_dependency 'rake',      '>= 10.3.2'
  s.add_development_dependency 'coveralls', '>= 0.7.1'
  s.add_development_dependency 'rspec',     '>= 3.1.0'
  s.add_development_dependency 'fuubar',    '>= 2.0.0'
  s.add_development_dependency 'timecop',   '>= 0.7.1'
end
