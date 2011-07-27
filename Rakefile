require 'bundler'
Bundler::GemHelper.install_tasks
require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << ['lib', 'test']
  t.pattern = "spec/*_spec.rb"
end
