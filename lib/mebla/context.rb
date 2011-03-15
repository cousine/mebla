require 'singleton'

# @private
module Mebla
  # Handles indexing and reindexing
  class Context
    include Singleton
    
    attr_reader  :indexed_models
    
    # @private
    def initialize
      @indexed_models = []
    end
    
    # @private
    # Adds a model to the list of indexed models
    def add_indexed_model(model)
      model = model.name if model.is_a?(Class)
      
      @indexed_models << model
      @indexed_models.uniq!
      @indexed_models.sort!
    end
    
    # Creates the indecies and indexes the data for all models or a list of models given
    # @params [*models] a list of symbols each representing a model name to be indexed
    # @return [nil]
    def index_data(*models)
      if models.empty?
        only_index = @indexed_models
      else
        only_index = models.collect{|m| m.to_s}
      end
      
      # Build up a bulk query to save processing and time
      bulk_query = ""
      
      # Start collecting documents
      only_index.each do |model|
        # Get the class
        to_index = model.classify.constantize
        # Create the index
        if to_index.create_index  
          # build the queries for this model
          to_index.all.only(to_index.search_fields).each do |document|
            attrs = document.attributes.dup # make sure we dont modify the document it self
            attrs.delete("_id") # the id is already added in the meta data of the action part of the query
            
            # convert the hash into json
            attrs_to_json = attrs.collect{|k,v| "\"#{k}\" : \"#{v}\""}.join(", ")
            
            # add to the bulk query
            bulk_query << <<-eos
              { "index" : { "_index" : "#{to_index.slingshot_index_name}", "_type" : "#{to_index.slingshot_type_name}", "_id" : "#{document.id.to_s}" } }
              {#{attrs_to_json}}
            eos
          end
        else
          raise ::Mebla::Errors::MeblaError.new("Could not create #{to_index.slingshot_index_name}' index !!!")
        end
      end
      
      # Add a new line to the query
      bulk_query << '\n'
      
      # Send the query
      response = Slingshot::Configuration.client.post "#{Slingshot::Configuration.url}/_bulk", bulk_query
      
      # Only refresh the indecies if no error ocurred
      unless response =~ /error/                
        # Refresh the indecies
        refresh_indecies
      else
        raise ::MeblaError::Errors::MeblaError.new("Indexing #{only_index.join(", ")} failed with the following response:\n #{response}")
      end
    rescue RestClient::Exception => error
      raise ::MeblaError::Errors::MeblaError.new("Indexing #{only_index.join(", ")} failed with the following error: #{error.message}")
    end
    
    # Rebuilds the indecies and indexes the data for all models or a list of models given
    # @params [*models] a list of symbols each representing a model name to rebuild it's index
    # @return [nil]
    def reindex_data(*models)
      if models.empty?
        only_reindex = @indexed_models
      else
        only_reindex = models.collect{|m| m.to_s}
      end
      
      # Get all models that should be reindexed
      only_reindex.each do |model|
        # Get the class
        to_reindex = model.classify.constantize
        # Drop the index
        unless to_reindex.drop_index
          raise ::Mebla::Errors::MeblaError.new("Could not drop #{to_reindex.slingshot_index_name}' index !!!")
        end
      end
      
      # Create the index and index the data
      index_data(models)      
    end
    
    
    private
    # Refreshes all indecies
    # @return [nil]
    def refresh_indecies
      @indexed_models.each do |model|
        indexed_model = model.classify.constantize        
        indexed_model.slingshot_index.refresh
      end
    end
  end
end