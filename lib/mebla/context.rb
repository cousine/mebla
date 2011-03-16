# @private
module Mebla
  # Handles indexing and reindexing
  class Context    
    attr_reader  :indexed_models, :slingshot_index, :slingshot_index_name
    attr_reader  :mappings
    
    # @private
    def initialize            
      @indexed_models = []
      @mappings = {}
      @slingshot_index = Slingshot::Index.new(Mebla::Configuration.instance.index)
      @slingshot_index_name = Mebla::Configuration.instance.index
    end
    
    # @private
    # Adds a model to the list of indexed models
    def add_indexed_model(model, mappings = {})      
      model = model.name if model.is_a?(Class)
      
      @indexed_models << model
      @indexed_models.uniq!
      @indexed_models.sort!
      
      @mappings.merge!(mappings)
    end
    
    # Deletes and rebuilds the index
    # @note Doesn't index the data, use Mebla::Context#reindex_data to rebuild the index and index the data
    # @return [nil]
    def rebuild_index
      # Only rebuild if the index exists
      raise ::Mebla::Errors::MeblaError.new("#{@slingshot_index_name} does not exist !! use #create_index to create the index first.") unless index_exists?

      # Delete the index
      if drop_index
        # Create the index
        return build_index
      end
    end
    
    # Creates and indexes the document
    # @note Doesn't index the data, use Mebla::Context#index_data to create the index and index the data
    # @return [Boolean] true if operation is successful
    def create_index
      # Only create the index if it doesn't exist
      raise ::Mebla::Errors::MeblaError.new("#{@slingshot_index_name} already exists !! use #rebuild_index to rebuild the index.") if index_exists?
      
      # Create the index
      build_index
    end
    
    # Deletes the index of the document
    # @return [Boolean] true if operation is successful
    def drop_index
      # Only drop the index if it exists
      return true unless index_exists?
      
      # Drop the index
      result = @slingshot_index.delete
      
      # Check that the index doesn't exist
      !index_exists?
    end
    
    # Checks if the index exists and is available
    # @return [Boolean] true if the index exists and is available, false otherwise
    def index_exists?
      begin
        result = Slingshot::Configuration.client.get "#{Mebla::Configuration.instance.url}/#{@slingshot_index_name}/_status"
        return (result =~ /error/) ? false : true
      rescue RestClient::ResourceNotFound
        return false
      end
    end
    
    # Creates the index and indexes the data for all models or a list of models given
    # @param *models a list of symbols each representing a model name to be indexed
    # @return [nil]
    def index_data(*models)
      if models.empty?
        only_index = @indexed_models
      else
        only_index = models.collect{|m| m.to_s}
      end
      
      # Build up a bulk query to save processing and time
      bulk_query = ""
      
      # Create the index
      if create_index
        # Start collecting documents
        only_index.each do |model|
          # Get the class
          to_index = model.camelize.constantize
          
          # Get the records    
          entries = []
          unless to_index.embedded?
            entries = to_index.all.only(to_index.search_fields)            
          else
            parent = to_index.embedded_parent
            access_method = to_index.embedded_as
            
           parent.all.each do |parent_record|
              entries += parent_record.send(access_method.to_sym).all.only(to_index.search_fields)
            end
          end
          
          # Build the queries for this model          
          entries.each do |document|
            attrs = document.attributes.dup # make sure we dont modify the document it self
            attrs["id"] = attrs.delete("_id") # the id is already added in the meta data of the action part of the query
            
            if document.embedded?
              parent_id = document.send(document.class.embedded_parent_foreign_key.to_sym).id.to_s        
              attrs[(document.class.embedded_parent_foreign_key + "_id").to_sym] = parent_id
              
              # Build add to the bulk query
              bulk_query << build_bulk_query(@slingshot_index_name, to_index.slingshot_type_name, document.id.to_s, attrs, parent_id)
            else
              # Build add to the bulk query
              bulk_query << build_bulk_query(@slingshot_index_name, to_index.slingshot_type_name, document.id.to_s, attrs)
            end
          end
        end
      else
        raise ::Mebla::Errors::MeblaError.new("Could not create #{@slingshot_index_name}!!!")
      end
      
      # Add a new line to the query
      bulk_query << '\n'      
      
      # Send the query
      response = Slingshot::Configuration.client.post "#{Mebla::Configuration.instance.url}/_bulk", bulk_query
      
      # Only refresh the index if no error ocurred
      unless response =~ /error/                
        # Refresh the index
        refresh_index
      else
        raise ::Mebla::Errors::MeblaError.new("Indexing #{only_index.join(", ")} failed with the following response:\n #{response}")
      end
    rescue RestClient::Exception => error
      raise ::Mebla::Errors::MeblaError.new("Indexing #{only_index.join(", ")} failed with the following error: #{error.message}")
    end
    
    # Rebuilds the index and indexes the data for all models or a list of models given
    # @param *models a list of symbols each representing a model name to rebuild it's index
    # @return [nil]
    def reindex_data(*models)      
      unless drop_index
        raise ::Mebla::Errors::MeblaError.new("Could not drop #{@slingshot_index_name}!!!")
      end        
      
      # Create the index and index the data
      index_data(models)      
    end
        
    # Refreshes the index
    # @return [nil]
    def refresh_index
      @slingshot_index.refresh      
    end
    
    private          
    # Builds the index according to the mappings set
    # @return [Boolean] true if the index was created successfully, false otherwise
    def build_index      
      # Create the index
      @slingshot_index.create :mappings => @mappings 
      
      # Check if the index exists
      index_exists?
    end
    
    # OPTIMIZE: should find a solution for not refreshing the index while indexing embedded documents
    # Builds a bulk index query
    # @return [String]
    def build_bulk_query(index_name, type, id, attributes, parent = nil)
      attrs_to_json = attributes.collect{|k,v| "\"#{k}\" : \"#{v}\""}.join(", ")
      <<-eos
        { "index" : { "_index" : "#{index_name}", "_type" : "#{type}", "_id" : "#{id}"#{", \"_parent\" : \"#{parent}\"" if parent}, "refresh" : "true"} }
        {#{attrs_to_json}}
      eos
    end
  end
end