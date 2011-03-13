require "mongoid"
require "slingshot"
require "mebla/errors/mebla_error"
require "mebla/mongoid/mebla"

module Mebla #:nodoc:
  def self.mongoid?
    !defined?(Mongoid).nil?
  end
  
  def self.slingshot?
    !defined?(Slingshot).nil?
  end
end