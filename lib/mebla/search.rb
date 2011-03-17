# @private
module Mebla
  # Handles all searching functions and chains search to define filters, sorting or facets.
  #
  # This example searches posts by tags, sorts and filters the results::
  #  
  # criteria = Post.search.terms(:tags, ['ruby', 'rails']).ascending(:publish_date).only(:author => ['cousine'])
  #
  # This will search the index for posts tagged 'ruby' or 'rails', arrange the results ascendingly according
  # to their publish dates, and filter the results by the author named 'cousine'.
  #
  # The search won't be executed unless we try accessing the results collection::
  #
  #  results = criteria.hits
  #
  # Or directly iterate the collection::
  #
  #  criteria.each do |result|
  #    ...
  #  end
  #
  # Mebla supports multiple methods of searching
  # 
  # You can either search by direct Lucene query::
  #  
  #  Mebla.search("query")
  #
  # Or by term::
  #
  #  Mebla.search.term(:field, "term")
  #
  # Or by terms::
  #
  #  Mebla.search.terms(:field, ["term 1", "term 2", ...])  
  class Search
    include Enumerable
    attr_reader :slingshot_search, :results    
    
    # Creates a new Search object
    # @param [String] query_string optional search query
    # @param [String, Symbol, Array] type_names a string, symbol or array representing the models to be searcheds
    def initialize(query_string = "", type_names = [])
      # Convert type names from string or symbol to array
      type_names = case true
        when type_names.is_a?(Symbol), type_names.is_a?(String)
          [type_names]      
        when type_names.is_a?(Array) && !type_names.empty?
          type_names.collect{|name| name.to_s}
        else
          []
        end
        
        @slingshot_search = Slingshot::Search::Search.new(Mebla.context.slingshot_index_name, {})
        # Add a type filter to return only certain types
        unless type_names.empty?
          only(:_type => type_names)
        end
        
        unless query_string.blank?
          query(query_string)
        end
    end
    
    # Creates a terms search criteria
    # @param [String, Symbol] field the field to search
    # @param [Array] values the terms to match
    # @param [Hash] options to refine the search
    # @return [Mebla::Search]
    #
    # Match Posts tagged with either 'ruby' or 'rails'::
    #
    #  Post.search.terms(:tags, ['ruby', 'rails'], :minimum_match => 1)
    def terms(field, values, options = {})      
      @slingshot_search = @slingshot_search.query
      @slingshot_search.instance_variable_get(:@query).terms(field, values, options)
      self
    end
    
    # Creates a term search criteria
    # @param [String, Symbol] field the field to search
    # @param [String] value term to match
    # @return [Mebla::Search]
    def term(field, value)
      @slingshot_search = @slingshot_search.query
      @slingshot_search.instance_variable_get(:@query).term(field, value)
      self
    end
    
    # Creates a Lucene query string search criteria
    # @param [String] query_string search query
    # @param [Hash] options to refine the search
    #
    # Match Posts with "Test Lucene query" as title::
    #
    #  Post.search.query("Test Lucene query", :default_field => "title")
    # 
    # You can also instead::
    #
    #  Post.search.query("title: Test Lucene query")
    #
    # Or to search all fields::
    #
    #  Post.search.query("Test Lucene query")
    #
    # @note For more information check {http://lucene.apache.org/java/2_4_0/queryparsersyntax.html  Lucene's query syntax}
    def query(query_string, options = {})
      @slingshot_search = @slingshot_search.query
      @slingshot_search.instance_variable_get(:@query).string(query_string, options)
      self
    end
    
    # Sorts results ascendingly
    # @param [String, Symbol] field to sort by
    # @return [Mebla::Search]
    def ascending(field)
      @slingshot_search = @slingshot_search.sort
      @slingshot_search.instance_variable_get(:@sort).send(field.to_sym, 'asc')
      self
    end
    
    # Sorts results descendingly
    # @param [String, Symbol] field to sort by
    # @return [Mebla::Search]
    def descending(field)
      @slingshot_search = @slingshot_search.sort
      @slingshot_search.instance_variable_get(:@sort).send(field.to_sym, 'desc')
      self
    end
    
    # Creates a new facet for the search
    # @param [String] name of the facet
    # @param [String, Symbol] field to create a facet for
    # @params [Hash] options
    # @return [Mebla::Search]
    #
    # Defining a global facet named "tags"::
    #
    #  Post.search("*").facet("tags", :tag, :global => true)
    # 
    # @note check {http://www.elasticsearch.org/guide/reference/api/search/facets/ elasticsearch's facet reference} for more information
    def facet(name, field, options={})
      # Get the hash
      facet_hash = @slingshot_search.instance_variable_get(:@facets)
      # Create a new Facet
      facet_obj = Slingshot::Search::Facet.new(name, options)
      facet_obj.terms(field)
      # Initialize the hash if its nil
      if facet_hash.nil?
        @slingshot_search.instance_variable_set(:@facets, {})
      end
      # Add the facet to the hash
      @slingshot_search.instance_variable_get(:@facets).update facet_obj.to_hash        
      self
    end
    
    # Filters the results according to the criteria
    # @param [*Hash] fields hash for each filter
    # @return [Mebla::Search]
    # 
    # Get all indexed Posts and filter them by tags and authors::
    #
    #  Post.search("*").only(:tag => ["ruby", "rails"], :author => ["cousine"])
    def only(*fields)
      return if fields.empty?
      fields.each do |field|
        @slingshot_search = @slingshot_search.filter(:terms, field)
      end
      self
    end
    
    # Performs the search and returns the results
    # @return [Mebla::ResultSet]
    def hits
      return @results if @results
      # Log search query
      Mebla.log("Searching:\n#{@slingshot_search.to_json.to_s}", :debug)
      response = @slingshot_search.perform.response
      Mebla.log("Response:\n#{response}", :info)
      @results = Mebla::ResultSet.new(response)
      # Log results statistics
      Mebla.log("Searched for:\n#{@slingshot_search.to_json.to_s}\ngot #{@results.total} documents in #{@results.time} ms", :debug)
      @results
    end
    
    # @private
    def entries
      hits.entries
    end
    
    # Retrieves the total number of hits
    # @return [Integer]
    def total
      hits.total
    end
    
    # Retrieves the time taken to perform the search in ms
    # @return [Float]
    def time
      hits.time
    end
    
    # Retrieves the facets
    # @return [Hash]
    #
    # Reading a facet named 'tags'::
    #
    #  facets = Post.search("*").facet("tags", :tag)
    #  facets["terms"].each do |term|
    #    puts "#{term['term']} - #{term['count']}"
    #  end
    def facets
      hits.facets
    end
    
    # Iterates over the results collection
    def each(&block)
      hits.each(&block)
    end
    
    alias_method :asc, :ascending
    alias_method :desc, :descending
  end
end