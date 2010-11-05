require 'rubygems'
require 'rake'
require 'rake/testtask'
require File.expand_path('../lib/mongo_mapper/plugins/version', __FILE__)

Rake::TestTask.new do |t|
  t.libs = %w(test)
  t.pattern = 'test/*_test.rb'
end
  
task :default => :test



desc 'Builds the gem'
task :build do
  sh "gem build mongo_mapper_acts_as_embedded_list.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  sh "gem install mongo_mapper_acts_as_embedded_list-#{MongoMapper::Plugins::ActsAsEmbeddedList::Version}"
end

desc 'Tags version, pushes to remote, and pushes gem'
task :release => :build do
  sh "git tag v#{MongoMapper::Plugins::ActsAsEmbeddedList::Version}"
  sh "git push origin master"
  sh "git push origin v#{MongoMapper::Plugins::ActsAsEmbeddedList::Version}"
  sh "gem push mongo_mapper_acts_as_embedded_list-#{MongoMapper::Plugins::ActsAsEmbeddedList::Version}.gem"
end
