# @private
module Mebla
  # Represents a set of search results  
  class ResultSet
    include Enumerable
    attr_reader :entries, :facets, :time, :total
    
    # OPTIMIZE: needs major refractoring
    # Creates a new result set from an elasticsearch response hash
    # @param response
    def initialize(response)
      # Keep the query time
      @time = response['took'] 
      # Keep the facets
      @facets = response['facets']
      # TODO: log an out of sync warning if total doesnt match the entries' count
      # Keep the query total to check against the count 
      @total = response['hits']['total']       
      
      # Be efficient only query the database once
      model_ids = {}
      
      # Collect results' ids
      response['hits']['hits'].each do |hit|
        model_class = hit['_type'].camelize.constantize        
        
        if model_class.embedded?
          unless model_ids[model_class]
            model_ids[model_class] = {}
          end
          # collect parent ids
          # {class => {parent_id => [ids]}}
          parent_id = hit['_source']['_parent']
          
          unless model_ids[model_class][parent_id]
            model_ids[model_class][parent_id] = []
          end
          
          model_ids[model_class][parent_id].push hit['_source']['id']
        else
          unless model_ids[model_class]
            model_ids[model_class] = []
          end
          # collect ids
          # {class => [ids]}
          model_ids[model_class].push hit['_source']['id']
        end
      end
      
      # Cast the results into their appropriate classes
      @entries = []
      
      model_ids.each do |model_class, ids|          
        unless model_class.embedded?
          # Retrieve the results from the database
          @entries += model_class.any_in(:_id => ids).entries
        else
          # Get the parent
          parent_class = model_class.embedded_parent
          access_method = model_class.embedded_as
          
          parent = parent_class.find ids.keys.first          
          
          # Retrieve the results from the database
          @entries += parent.send(access_method.to_sym).any_in(:_id => ids.values.first).entries
        end
      end        
    end
    
    # Iterates over the collection    
    def each(&block)
      @entries.each(&block)
    end
  end
end