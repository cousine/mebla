# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "mebla"
  s.version = "1.1.14"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Omar Mekky"]
  s.date = "2012-01-04"
  s.description = "\n    An elasticsearch wrapper for mongoid odm based on slingshot. Makes integration between ElasticSearch full-text \n    search engine and Mongoid documents seemless and simple.\n  "
  s.email = "omar.mekky@mashsolvents.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    ".rspec",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "TODO.md",
    "VERSION",
    "lib/generators/mebla/install/USAGE",
    "lib/generators/mebla/install/install_generator.rb",
    "lib/generators/mebla/install/templates/mebla.yml",
    "lib/mebla.rb",
    "lib/mebla/configuration.rb",
    "lib/mebla/context.rb",
    "lib/mebla/errors.rb",
    "lib/mebla/errors/mebla_configuration_exception.rb",
    "lib/mebla/errors/mebla_error.rb",
    "lib/mebla/errors/mebla_fatal.rb",
    "lib/mebla/errors/mebla_index_exception.rb",
    "lib/mebla/errors/mebla_synchronization_exception.rb",
    "lib/mebla/log_subscriber.rb",
    "lib/mebla/mongoid/mebla.rb",
    "lib/mebla/railtie.rb",
    "lib/mebla/result_set.rb",
    "lib/mebla/search.rb",
    "lib/mebla/tasks.rb",
    "mebla.gemspec",
    "spec/fixtures/models.rb",
    "spec/fixtures/mongoid.yml",
    "spec/mebla/indexing_spec.rb",
    "spec/mebla/searching_spec.rb",
    "spec/mebla/synchronizing_spec.rb",
    "spec/mebla_helper.rb",
    "spec/mebla_spec.rb",
    "spec/spec_helper.rb",
    "spec/support/mongoid.rb",
    "spec/support/rails.rb"
  ]
  s.homepage = "http://github.com/cousine/mebla"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.11"
  s.summary = "An elasticsearch wrapper for mongoid odm based on slingshot."

  if s.respond_to? :specification_version then
    s.specification_version = 3
end

