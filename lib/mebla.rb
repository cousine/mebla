require "mongoid"
require "slingshot"
require "mebla/configuration"
require "mebla/context"
require "mebla/result_set"
require "mebla/errors/mebla_error"
require "mebla/mongoid/mebla"
require "mebla/railtie" if defined?(Rails)

module Mebla #:nodoc:
  
  @@mebla_mutex = Mutex.new
  @@context      = nil
  
  def self.context
    if @@context.nil?
      @@mebla_mutex.synchronize do
        if @@context.nil?
          @@context = Mebla::Context.new          
        end
      end
    end
    
    @@context
  end
  
  def self.reset_context!
    @@mebla_mutex.synchronize do
      @@context = nil
    end
  end
  
  def self.mongoid?
    !defined?(Mongoid).nil?
  end
  
  def self.slingshot?
    !defined?(Slingshot).nil?
  end
  
  def self.elasticsearch?
    result = Slingshot::Configuration.client.get "#{Slingshot::Configuration.url}/_status"
    return (result =~ /error/) ? false: true
  rescue RestClient::Exception
    false
  end
  
  def self.configure(&block)
    yield Mebla::Configuration.instance
  end
end