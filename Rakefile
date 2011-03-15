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
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  gem.add_runtime_dependency 'slingshot-rb', '~> 0.0.5'
  gem.add_runtime_dependency 'mongoid', '2.0.0.rc.7'
  gem.add_runtime_dependency 'bson', '1.2.0'
  gem.add_runtime_dependency 'bson_ext', '1.2.0'
  
  gem.add_development_dependency 'rspec', '~> 2.3.0'
  gem.add_development_dependency 'yard', '~> 0.6.0'
  gem.add_development_dependency 'bundler', '~> 1.0.0'
  gem.add_development_dependency 'jeweler', '~> 1.5.2'
  gem.add_development_dependency 'rcov', '>= 0'
  gem.add_development_dependency 'mongoid-rspec', '1.4.1'
  gem.add_development_dependency 'database_cleaner', '0.6.4'
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
