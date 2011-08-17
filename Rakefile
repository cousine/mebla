# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "mebla"
  gem.homepage = "http://github.com/cousine/mebla"
  gem.license = "MIT"
  gem.summary = %Q{An elasticsearch wrapper for mongoid odm based on slingshot.}
  gem.description = %Q{
    An elasticsearch wrapper for mongoid odm based on slingshot. Makes integration between ElasticSearch full-text 
    search engine and Mongoid documents seemless and simple.
  }
  gem.email = "omar.mekky@mashsolvents.com"
  gem.authors = ["Omar Mekky"]
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
