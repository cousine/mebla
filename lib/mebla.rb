require 'active_support'
require 'mebla/railtie' if defined?(Rails)

# @private
module Mebla
  extend ActiveSupport::Autoload
  
  # Dependencies
  autoload :Mongoid,  'mongoid'
  autoload :Slingshot,  'slingshot'
  # Main modules
  autoload :Configuration
  autoload :Context
  autoload :LogSubscriber
  autoload :ResultSet
  autoload :Search
  # Errors
  autoload :Errors
  # Mongoid extensions
  autoload :Mebla,  'mebla/mongoid/mebla'  
    
  # Register the logger
  Mebla::LogSubscriber.attach_to :mebla
  
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
  
  
  # Writes out a message to the log file according to the level given
  # @note If no level is given a message of type Logger::UNKNOWN will be written to the log file
  # @param [String] message
  # @param [Symbol] level can be :debug, :warn or :info
  # @return [nil]
  def self.log(message, level = :none)    
    case level
    when :debug
      hook = "mebla_debug.mebla"
    when :warn
      hook = "mebla_warn.mebla"
    when :info
      hook = "mebla_info.mebla"
    else
      hook = "mebla_unknown.mebla"
    end
    
    ::ActiveSupport::Notifications.
      instrument(hook, :message => message)
  end  
  
  # Search the index
  # @param [String] query a string representing the search query
  # @param [String, Symbol, Array] type_names a string, symbol or array representing the models to be searcheds
  # @return [Mebla::Search]
  #
  # Search for all documents with a field 'title' with a value 'Testing Search'::
  #
  #  Mebla.search "title: Testing Search"  
  def self.search(query = "", type_names = nil)
    Mebla::Search.new(query, type_names)
  end
end