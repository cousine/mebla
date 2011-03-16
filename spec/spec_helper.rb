$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'mebla'
require 'bundler'

Bundler.require :default, :development

require "#{File.dirname(__FILE__)}/mebla_helper"
require "#{File.dirname(__FILE__)}/../lib/mebla"

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  require 'database_cleaner'

  mebla = MeblaHelper.new  
  mebla.setup_mongoid
  
  require "#{File.dirname(__FILE__)}/fixtures/models"
  
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.orm = "mongoid"
  end

  config.before(:each) do
    DatabaseCleaner.clean
  end  
  
  config.before(:suite) do
    Mebla.context.create_index
  end
  
  config.after(:suite) do
    Mebla.context.drop_index
  end
end
