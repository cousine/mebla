require "mongoid"
require "slingshot"
require "mebla/context"
require "mebla/errors/mebla_error"
require "mebla/mongoid/mebla"
require "mebla/railtie" if defined?(Rails)

module Mebla #:nodoc:
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
end