require "mongoid"
require "slingshot"

module Mebla #:nodoc:
  def self.mongoid?
    !defined?(Mongoid).nil?
  end
  
  def self.slingshot?
    !defined?(Slingshot).nil?
  end
end