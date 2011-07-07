# A wrapper for slingshot  elastic-search adapter for Mongoid
module Mebla
  # Represents a set of search results  
  class ResultSet
    include Enumerable
    attr_reader :entries, :facets, :time, :total
    
    # --
    # OPTIMIZE: needs major refractoring
    # ++
    
    # Creates a new result set from an elasticsearch response hash
    # @param response
    def initialize(response)
      # Keep the query time
      @time = response['took'] 
      # Keep the facets      
      @facets = response['facets']
      # Keep the query total to check against the count 
      @total = response['hits']['total']       
      
      # Be efficient only query the database once
      model_ids = []
      
      # Collect results' ids
      response['hits']['hits'].each do |hit|
        model_class = hit['_type'].camelize.constantize        
        model_ids << [model_class]

        if model_class.embedded?
          model_class_collection = model_ids.assoc(model_class)
          # collect parent ids
          # [class, [parent_id, ids]]
          parent_id = hit['_source']['_parent']
          
          model_class_collection << [parent_id]
          
          model_class_collection.assoc(parent_id) << hit['_source']['id']
        else
          # collect ids
          # [class, ids]
          model_ids.assoc(model_class) << hit['_source']['id']
        end
      end
      
      # Cast the results into their appropriate classes
      @entries = []

      model_ids.each do |model_class_collection|          
        model_class = model_class_collection.first
        ids = model_class_collection.drop(1)

        unless model_class.embedded?
          # Retrieve the results from the database
          ids.each do |id|
            @entries << model_class.find(id)
          end
        else
          # Get the parent
          parent_class = model_class.embedded_parent
          access_method = model_class.embedded_as
          
          ids.each do |parent_id_collection|
            parent_id = parent_id_collection.first
            entries_ids = parent_id_collection.drop(1)
            
            parent = parent_class.find parent_id
            
            # Retrieve the results from the database
            entries_ids.each do |entry_id|
              @entries << parent.send(access_method.to_sym).find(entry_id)
            end
          end
        end
      end
            
      Mebla.log("WARNING: Index not synchronized with the database; index total hits: #{@total}, retrieved documents: #{self.count}", :warn) if @total != self.count
    end
    
    # Iterates over the collection    
    def each(&block)
      @entries.each(&block)
    end
    
    # Returns the item with the given index
    # @param [Integer] index
    def [](index)
      @entries[index]
    end
  end
end