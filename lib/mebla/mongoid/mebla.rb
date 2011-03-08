module Mongoid  # :nodoc:
  # A wrapper for slingshot  elastic-search adapter for Mongoid
  module Mebla
    extend ActiveSupport::Concern
    included do
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
      
      cattr_accessor  :slingshot_index
      cattr_accessor  :search_fields      
      cattr_accessor  :index_options
      cattr_accessor  :index_mappings
    end
    
    module ClassMethods
      # Defines which fields should be indexed and searched
      # @param fields to index and search in
      # @return [nil]
      #
      # Example:: 
      #  Defines a search index with custom mappings on "body"
      #   class Document
      #    include Mongoid::Document
      #    include Mongoid::Mebla
      #    field :title
      #    field :body
      #    field :publish_date, :type => Date
      #    ...
      #    search_in :title, :publish_date, :body => { :boost => 2.0, :analyzer => 'snowball' }
      #   end
      def search_in(*opts)
        # Extract advanced indeces
        options = opts.extract_options!.symbolize_keys
        # Extract simple indeces
        attrs = opts.flatten
        
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
      end
      
      # Deletes and rebuilds the index
      # @return [nil]
      def rebuild_index
        # Create the index and keep track of it
        self.slingshot_index = Slingshot.index self.slingshot_index_name do
          delete
          create :mappings => {
            self.singular_slingshot_index_name.to_sym => {
              :properties => self.index_mappings
            }
          }
        end
      end
      
      private
      def slingshot_index_name #:nodoc:
        "#{self.collection_name}_#{I18n.locale.to_s.split("-").first}"
      end
      
      def singular_slingshot_index_name #:nodoc:
        "#{self.model_name.under_score}_#{I18n.locale.to_s.split("-").first}"
      end
    end
  end
end