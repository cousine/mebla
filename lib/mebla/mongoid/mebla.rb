# @private
module Mongoid
  # A wrapper for slingshot  elastic-search adapter for Mongoid
  module Mebla
    extend ActiveSupport::Concern
    included do
      # Used to properly represent data types
      unless defined?(SLINGSHOT_TYPE_MAPPING)
        SLINGSHOT_TYPE_MAPPING = {
          'Date' => 'date',
          'DateTime' => 'date',
          'Time' => 'date',
          'Float' => 'float',
          'Integer' => 'integer',
          'BigDecimal' => 'float',
          'Boolean' => 'boolean'          
        }
      end
      
      cattr_accessor  :embedded_parent
      cattr_accessor  :embedded_parent_foreign_key      
      cattr_accessor  :index_mappings
      cattr_accessor  :index_options
      cattr_accessor  :search_fields      
      cattr_accessor  :slingshot_index
      cattr_accessor  :whiny_indexing   # set to true to raise errors if indexing fails
      
      # make sure critical data remain read only
      private_class_method :"slingshot_index=", :"search_fields=", :"index_options=", :"index_mappings=",
                                          :"embedded_parent_foreign_key=", :"embedded_parent="
      
      # add callbacks to synchronize modifications with elasticsearch
      after_save        :add_to_index
      before_destroy :remove_from_index
      
      # by default if synchronizing fails no error is raised
      self.whiny_indexing = false
    end
    
    module ClassMethods
      # Defines which fields should be indexed and searched
      # @param [*opts] fields
      # @return [nil]
      #
      # Example:: 
      #  Defines a search index on a normal document with custom mappings on "body"
      #   class Document
      #    include Mongoid::Document
      #    include Mongoid::Mebla
      #    field :title
      #    field :body
      #    field :publish_date, :type => Date
      #    ...
      #    search_in :title, :publish_date, :body => { :boost => 2.0, :analyzer => 'snowball' }
      #   end
      #      
      #  Defines a search index on an embedded document with a single parent and custom mappings on "body"
      #   class Document
      #    include Mongoid::Document
      #    include Mongoid::Mebla
      #    field :title
      #    field :body
      #    field :publish_date, :type => Date
      #    ...
      #    embedded_in :category
      #    search_in :title, :publish_date, :body => { :boost => 2.0, :analyzer => 'snowball' }, :embedded_in => :category
      #   end
      #
      #  Defines a search index on an embedded document with a single parent, an unconventional foreign key and custom mappings on "body"
      #   class Document
      #    include Mongoid::Document
      #    include Mongoid::Mebla
      #    field :title
      #    field :body
      #    field :publish_date, :type => Date
      #    ...
      #    embedded_in :section, :class_name => :category
      #    search_in :title, :publish_date, :body => { :boost => 2.0, :analyzer => 'snowball' }, :embedded_in => { :class_name => :category, :foreign_key => :section_id }
      #   end
      def search_in(*opts)
        # Extract advanced indeces
        options = opts.extract_options!.symbolize_keys
        # Extract simple indeces
        attrs = opts.flatten
        
        
        # If this document is embedded check for the embedded_in option and raise an error if none is specified
        # Example::
        #  embedded in a regular class (e.g.: using the default convention for naming the foreign key)
        #    :embedded_in => :parent
        #  embedded in a class using a non-conventional foreign key
        #    :embedded_in => {:class_name => :parent, :foreign_key => :fk_id}
        if self.embedded?
          if (embedor = options.delete(:embedded_in))            
            case embedor.class
            when Symbol, String
              self.embedded_parent = embedor.to_s.classify.constantize
              self.embedded_parent_foreign_key = embedor.to_s + "_id"
            when Hash
              self.embedded_parent = embedor[:class_name].to_s.classify.constantize
              self.embedded_parent_foreign_key = embedor[:foreign_key]
            end
          else
            raise ::Mebla::Errors::MeblaError.new("#{self.model_name} is embedded: embedded_in option should be set to the parent class if the document is embedded.")
          end
        end
        
        # Keep track of searchable fields (for indexing)
        self.search_fields = attrs + options.keys
        
        # Generate simple indeces' mappings
        attrs_mappings = {}
        
        attrs.each do |attribute|
          attrs_mappings[attribute] = {:type => SLINGSHOT_TYPE_MAPPING[self.fields[attribute].to_s] || "string"}
        end
        
        # Generate advanced indeces' mappings
        opts_mappings = {}
        
        options.each do |opt, properties|          
          opts_mappings[opt] = {:type => SLINGSHOT_TYPE_MAPPING[self.fields[opt].to_s] || "string" }.merge!(properties)
        end
        
        # Merge mappings
        self.index_mappings = {}.merge!(attrs_mappings).merge!(opts_mappings)
        
        # Initialize the index
        self.slingshot_index  = Slingshot::Index.new(self.slingshot_index_name)
        
        # Keep track of indexed models (for bulk indexing)
        ::Mebla::Context.instance.add_indexed_model(self)
      end
      
      # TODO: Searching is incomplete
      # Searches the model
      # @return [Collection]
      def search(query, &block)
        if block_given?
          Slingshot::Search::Search.new(self.slingshot_index_name, {}, &block).perform
        else
          Slingshot::Search::Search.new(self.slingshot_index_name).query do 
            string(query)
          end
        end
      end
            
      # Deletes and rebuilds the index
      # @note Doesn't index the data, use Mebla::Context#reindex_data to rebuild the index and index the data
      # @return [nil]
      def rebuild_index
        # Only rebuild if the index exists
        raise ::Mebla::Errors::MeblaError.new("#{self.slingshot_index_name} does not exist !! use #create_index to create the index first.") unless self.index_exists?        
        
        # Delete the index
        self.slingshot_index.delete
        # Create the index
        build_index
      end
            
      # Creates and indexes the document
      # @note Doesn't index the data, use Mebla::Context#index_data to create the index and index the data
      # @return [Boolean] true if operation is successful
      def create_index
        # Only create the index if it doesn't exist
        raise ::Mebla::Errors::MeblaError.new("#{self.slingshot_index_name} already exists !! use #rebuild_index to rebuild the index.") if self.index_exists?
        
        # Create the index
        build_index
      end
      
      # Deletes the index of the document
      # @return [Boolean] true if operation is successful
      def drop_index
        # Only drop the index if it exists
        raise ::Mebla::Errors::MeblaError.new("#{self.slingshot_index_name} does not exist !! use #create_index to create the index first.") unless self.index_exists?
        
        # Drop the index
        result = self.slingshot_index.delete
        
        # Check that the index doesn't exist
        !self.index_exists?
      end
      
      # Checks if the index exists and is available
      # @return [Boolean] true if the index exists and is available, false otherwise
      def index_exists?
        begin
          result = Slingshot::Configuration.client.get "#{Slingshot::Configuration.url}/#{self.slingshot_index_name}/_status"
          return (result =~ /error/) ? false : true
        rescue RestClient::ResourceNotFound
          return false
        end
      end
      
      # Retrieves the index name of the model
      # @return [String]
      def slingshot_index_name
        "#{self.collection_name}"
      end
      
      # Retrieves the type name of the model 
      # (used to populate the _type variable while indexing)
      # @return [String]
      def slingshot_type_name #:nodoc:
        "#{self.model_name.underscore}"
      end
      
      # Enables the modification of records without indexing
      # @return [nil]
      # Example::
      #  create record without it being indexed
      #    Class.without_indexing do
      #      create :title => "This is not indexed", :body => "Nothing will be indexed within this block"      
      #    end
      # @note you can skip indexing to create, update or delete records without affecting the index
      def without_indexing(&block)
        skip_callback(:save, :after, :add_to_index)
        skip_callback(:destroy, :before, :remove_from_index)
        yield
        set_callback(:save, :after, :add_to_index)
        set_callback(:destroy, :before, :remove_from_index)
      end
      
      private
      # Prepare the mappings required for this document
      # @return [Hash]
      def prepare_mappings
        if self.embedded?
          mappings = {
            :_parent => { :type => self.embedded_parent.name.underscore }            
          }
        else
          mappings = {}
        end
        
        mappings.merge!({
          :properties => self.index_mappings
        })
      end
            
      # Builds the index according to the mappings set
      # @return [Boolean] true if the index was created successfully, false otherwise
      def build_index
        # Prepare mappings
        mappings = prepare_mappings
        
        # Create the index
        self.slingshot_index.create :mappings => {
          self.slingshot_type_name.to_sym => mappings
        }
        
        # Check if the index exists
        self.index_exists?
      end
    end
    
    private
    # Adds the document to the index
    # @return [Boolean] true if the operation is successful
    def add_to_index
      return false unless self.class.index_exists? # only try to index if the index exists      
      
      # Prepare attributes to hash
      to_index_hash = {:id => self.id.to_s}
      
      # If the document is embedded set _parent to the parent's id
      if self.embedded?
        to_index_hash.merge({ 
          :_parent => self.attributes[self.class.embedded_parent_foreign_key].to_s 
        })
      end
      
      # Add indexed fields to the hash
      self.search_fields.each do |sfield|
        to_index_hash[sfield] = self.attributes[sfield]
      end
      
      # Index the data under its correct type
      self.slingshot_index.store(self.class.slingshot_type_name.to_sym, to_index_hash)
      
      # Refresh the index
      refresh_index
      return true
    rescue => error      
      raise error if self.class.whiny_indexing # whine when mebla is not able to index
      return false
    end
    
    # Deletes the document from the index
    # @return [Boolean] true if the operation is successful
    def remove_from_index
      return false unless self.class.index_exists? # only try to index if the index exists      
      # Delete the document
      response = Slingshot::Configuration.client.delete "#{Slingshot::Configuration.url}/#{self.class.slingshot_index_name}/#{self.class.slingshot_type_name}/#{self.id.to_s}"
      # Refresh the index
      refresh_index
      return true
    rescue => error
      raise error if self.class.whiny_indexing # whine when mebla is not able to index
      return false
    end
    
    # Refreshes the index
    # @return [Object]
    def refresh_index
      return false unless self.class.index_exists? # only try to index if the index exists
      # Refresh the index
      self.slingshot_index.refresh
      return true
    rescue => error
      raise error if self.class.whiny_indexing # whine when mebla is not able to index
      return false
    end
  end
end