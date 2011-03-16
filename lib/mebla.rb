require "mongoid"
require "slingshot"
require "mebla/configuration"
require "mebla/context"
require "mebla/result_set"
require "mebla/errors/mebla_error"
require "mebla/mongoid/mebla"
require "mebla/railtie" if defined?(Rails)

# TODO: add documentation
# @private
module Mebla
  
  @@mebla_mutex = Mutex.new
  @@context      = nil
  
  # Returns Mebla's context for minipulating the index
  # @return [nil]
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
  
  # Resets the context (reloads Mebla)
  # @return [nil]
  def self.reset_context!
    @@mebla_mutex.synchronize do
      @@context = nil
    end
  end
  
  # Check if mongoid is loaded
  # @return [Boolean]
  def self.mongoid?
    !defined?(Mongoid).nil?
  end
  
  # Check if slingshot is loaded
  # @return [Boolean]
  def self.slingshot?
    !defined?(Slingshot).nil?
  end
  
  # Check if elasticsearch is running
  # @return [Boolean]
  def self.elasticsearch?
    result = Slingshot::Configuration.client.get "#{Slingshot::Configuration.url}/_status"
    return (result =~ /error/) ? false: true
  rescue RestClient::Exception
    false
  end
  
  # Configure Mebla  
  #
  # Example::
  # 
  #   Mebla.configure do |config|
  #     index = "mebla_index"
  #     host = "localhost"
  #     port = 9200
  #   end
  def self.configure(&block)
    yield Mebla::Configuration.instance
  end
end