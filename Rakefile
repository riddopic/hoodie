
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'yard'

desc 'Run tests'
RSpec::Core::RakeTask.new(:spec)

desc 'Run Rubocop on the gem'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['lib/**/*.rb', 'spec/**/*.rb']
  task.fail_on_error = true
end

YARD::Config.load_plugin 'redcarpet-ext'
YARD::Rake::YardocTask.new do |t|
  additional_docs = %w[ CHANGELOG.md LICENSE.md README.md ]
  t.files = ['lib/*.rb', '-'] + additional_docs
  t.options = ['--readme=README.md', '--markup=markdown', '--verbose']
end

desc 'Build documentation'
task doc: [:yard]

task default: [:spec, :rubocop, :doc, :build, :install]
