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
  # Errors
  autoload :Errors  
  # Mongoid extensions
  autoload :Mebla,  'mebla/mongoid/mebla'  
  
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
  # @note If no level is given a message of type Logger::UNKOWN will be written to the log file
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
      hook = "mebla_unkown.mebla"
    end
    
    ::ActiveSupport::Notifications.
      instrument(hook, :message => message)
  end  
  
  # Search the index using Slingshot search DSL
  # @param type_names a string, symbol or array representing the models to be searcheds
  # @return [ResultSet]
  #
  # Search for all documents with a field title with a value 'Testing Search'::
  #
  #  Mebla.search do
  #   query do
  #    string "title: Testing Search"
  #   end
  #  end
  #
  # @note For more information about Slingshot search DSL, check http://karmi.github.com/slingshot
  def self.search(type_names = [], &block)
    # Convert type names from string or symbol to array
    type_names = case true
      when type_names.is_a?(Symbol), type_names.is_a?(String)
        [type_names]      
      when type_names.is_a?(Array)
        type_names.collect{|name| name.to_s}
      else
        []
      end
    # Create slingshot search object
    search_obj = Slingshot::Search::Search.new(::Mebla.context.slingshot_index_name, {}, &block)
    # Add a type filter to return only certain types
    search_obj = search_obj.filter(:terms, :_type => type_names) unless type_names.empty?
    # Log search query
    log("Searching:\n#{search_obj.to_json.to_s}", :debug)
    # Perform the search and parse the response
    results  = Mebla::ResultSet.new(search_obj.perform.response)
    # Log results statistics
    log("Searched for:\n#{search_obj.to_json.to_s}\ngot #{results.total} in #{results.time}", :debug)
    # Return the results
    return results
  end
end