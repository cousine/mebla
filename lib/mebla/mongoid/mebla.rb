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
            
      class_inheritable_accessor :embedded_as      
      class_inheritable_accessor :embedded_parent
      class_inheritable_accessor :embedded_parent_foreign_key      
      class_inheritable_accessor :slingshot_mappings      
      class_inheritable_accessor :search_fields        
      class_inheritable_accessor :search_relations        
      class_inheritable_accessor :whiny_indexing   # set to true to raise errors if indexing fails
        
      # make sure critical data remain read only
      private_class_method :"search_fields=", :"slingshot_mappings=",
                                          :"embedded_parent_foreign_key=", :"embedded_parent=", :"embedded_as="
      
      # add callbacks to synchronize modifications with elasticsearch
      after_save        :add_to_index
      before_destroy :remove_from_index
      
      # by default if synchronizing fails no error is raised
      self.whiny_indexing = false
    end
    
    # Defines class methods for Mongoid::Mebla
    module ClassMethods
      # Defines which fields should be indexed and searched
      # @param [*opts] fields
      # @return [nil]
      #      
      # Defines a search index on a normal document with custom mappings on "body"::
      #
      #  class Document
      #   include Mongoid::Document
      #   include Mongoid::Mebla
      #   field :title
      #   field :body
      #   field :publish_date, :type => Date
      #   #...
      #   search_in :title, :publish_date, :body => { :boost => 2.0, :analyzer => 'snowball' }
      #  end
      #      
      # Defines a search index on a normal document with an index on a field inside a relation::
      #
      #  class Document
      #   include Mongoid::Document
      #   include Mongoid::Mebla
      #   field :title
      #   field :body
      #   field :publish_date, :type => Date
      #
      #   referenced_in :blog  
      #   #...
      #   # relations mappings are detected automatically
      #   search_in :title, :publish_date, :body => { :boost => 2.0, :analyzer => 'snowball' }, :search_relations => {
      #     :blog => [:author, :name]
      #   }
      #  end
      #
      # Defines a search index on a normal document with an index on method "permalink"::
      #
      #  class Document
      #   include Mongoid::Document
      #   include Mongoid::Mebla
      #   field :title
      #   field :body
      #   field :publish_date, :type => Date
      #
      #   def permalink
      #     self.title.gsub(/\s/, "-").downcase
      #   end      
      #   #...
      #   # methods can also define custom mappings if needed
      #   search_in :title, :publish_date, :permalink, :body => { :boost => 2.0, :analyzer => 'snowball' }
      #  end      
      #
      # Defines a search index on an embedded document with a single parent and custom mappings on "body"::
      #
      #  class Document
      #   include Mongoid::Document
      #   include Mongoid::Mebla
      #   field :title
      #   field :body
      #   field :publish_date, :type => Date
      #   #...
      #   embedded_in :category
      #   search_in :title, :publish_date, :body => { :boost => 2.0, :analyzer => 'snowball' }, :embedded_in => :category
      #  end      
      def search_in(*opts)        
        # Extract advanced indeces
        options = opts.extract_options!.symbolize_keys
        # Extract simple indeces
        attrs = opts.flatten
        
        
        # If this document is embedded check for the embedded_in option and raise an error if none is specified
        # Example::
        #  embedded in a regular class (e.g.: using the default convention for naming the foreign key)
        #    :embedded_in => :parent        
        if self.embedded?          
          if (embedor = options.delete(:embedded_in))
            relation = self.relations[embedor.to_s]
            
            # Infer the attributes of the relation
            self.embedded_parent = relation.class_name.constantize
            self.embedded_parent_foreign_key = relation.key.to_s
            self.embedded_as = relation[:inverse_of] || relation.inverse_setter.to_s.gsub(/=$/, '')
            
            if self.embedded_as.blank?
              raise ::Mebla::Errors::MeblaConfigurationException.new("Couldn't infer #{embedor.to_s} inverse relation, please set :inverse_of option on the relation.")
            end
          else
            raise ::Mebla::Errors::MeblaConfigurationException.new("#{self.name} is embedded: embedded_in option should be set to the parent class if the document is embedded.")
          end
        end
        
        self.search_relations = {}
        # Keep track of relational indecies
        unless (relations_inedcies = options.delete(:search_relations)).nil?
          relations_inedcies.each do |relation, index|
            self.search_relations[relation] = index
          end
        end
        
        # Keep track of searchable fields (for indexing)
        self.search_fields = attrs + options.keys        
        
        # Generate simple indeces' mappings
        attrs_mappings = {}
        
        attrs.each do |attribute|
          unless (attr_field = self.fields[attribute.to_s]).nil?
            unless (field_type = attr_field.type.to_s) == "Array" # arrays don't need mappings
              attrs_mappings[attribute] = {:type => SLINGSHOT_TYPE_MAPPING[field_type] || "string"}
            end
          else
            if self.instance_methods.include?(attribute.to_s)
              attrs_mappings[attribute] = {:type => "string"}
            else
              ::Mebla::Errors::MeblaConfigurationException.new("Invalid field #{attribute.to_s} defined for indexing #{self.name}.")
            end
          end
        end
        
        # Generate advanced indeces' mappings
        opts_mappings = {}
        
        options.each do |opt, properties|
          unless (attr_field = self.fields[opt.to_s]).nil?
            unless (field_type = attr_field.type.to_s) == "Array"
              opts_mappings[opt] = {:type => SLINGSHOT_TYPE_MAPPING[field_type] || "string" }.merge!(properties)
            end
          else
            if self.instance_methods.include?(opt.to_s)
              opts_mappings[opt] = {:type => "string"}.merge!(properties)                
            else
              ::Mebla::Errors::MeblaConfigurationException.new("Invalid field #{opt.to_s} defined for indexing #{self.name}.")
            end
          end
        end
        
        # Merge mappings
        self.slingshot_mappings = {}.merge!(attrs_mappings).merge!(opts_mappings)        
        
        # Keep track of indexed models (for bulk indexing)
        ::Mebla.context.add_indexed_model(self, self.slingshot_type_name.to_sym => prepare_mappings)
      end
            
      # Searches the model using Slingshot search DSL      
      # @param [String] query a string representing the search query  
      # @return [Mebla::Search]
      #
      # Search for all posts with a field 'title' of value 'Testing Search'::
      #
      #  Post.search "title: Testing Search" 
      def search(query = "")
        ::Mebla.search(query, self.slingshot_type_name)
      end
      
      # Retrieves the type name of the model 
      # (used to populate the _type variable while indexing)
      # @return [String]
      def slingshot_type_name
        "#{self.name.underscore}"        
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
      
      # Checks if the class is a subclass
      # @return [Boolean] true if class is a subclass
      def sub_class?
        self.superclass != Object
      end
      
      private
      # Prepare the mappings required for this document
      # @return [Hash]
      def prepare_mappings
        if self.embedded?
          mappings = {
            :_parent => { :type => self.embedded_parent.name.underscore },
            :_routing => {
              :required => true,
              :path => self.embedded_parent_foreign_key  + "_id"
            }
          }
        else
          mappings = {}
        end
                
        mappings.merge!({
          :properties => self.slingshot_mappings
        })
      end
    end
    
    private
    # Adds the document to the index
    # @return [Boolean] true if the operation is successful
    def add_to_index      
      return false unless ::Mebla.context.index_exists? # only try to index if the index exists      
      
      # Prepare attributes to hash
      to_index_hash = {:id => self.id.to_s}
      
      # If the document is embedded set _parent to the parent's id
      if self.embedded?
        parent_id = self.send(self.class.embedded_parent_foreign_key.to_sym).id.to_s        
        to_index_hash.merge!({ 
          (self.class.embedded_parent_foreign_key + "_id").to_sym => parent_id,
          :_parent => parent_id
        })
      end
      
      # Add indexed fields to the hash
      self.class.search_fields.each do |sfield|
        if self.class.fields[sfield.to_s]
          to_index_hash[sfield] = self.attributes[sfield.to_s]
        else
          to_index_hash[sfield] = self.send(sfield)
        end
      end
      
      # Add indexed relations to the hash      
      self.class.search_relations.each do |relation, fields|        
        entries = self.send(relation.to_sym)
        
        next if entries.nil?
        
        if entries.is_a?(Array)
          next if entries.empty?
          to_index_hash[relation] = []
          entries.each do |entry|
            if fields.is_a?(Array)
              to_index_hash[relation] << entry.attributes.reject{|key, value| !fields.include?(key.to_sym)}
            else
              to_index_hash[relation] << { fields => entry.attributes[fields.to_s] }
            end
          end
        else          
          to_index_hash[relation] = {}
          if fields.is_a?(Array)
            to_index_hash[relation].merge!(entries.attributes.reject{|key, value| !fields.include?(key.to_sym)})
          else
            to_index_hash[relation].merge!({ fields => entries.attributes[fields.to_s] })
          end
        end
      end      
      
      ::Mebla.log("Indexing #{self.class.slingshot_type_name}: #{to_index_hash.to_s}", :debug)
      
      # Index the data under its correct type
      response = ::Mebla.context.slingshot_index.store(self.class.slingshot_type_name.to_sym, to_index_hash)
      
      ::Mebla.log("Response for indexing #{self.class.slingshot_type_name}: #{response.to_s}", :debug)
      
      # Refresh the index
      ::Mebla.context.refresh_index
      return true
    rescue => error
      raise_synchronization_exception(error)
      
      return false
    end
        
    # Deletes the document from the index
    # @return [Boolean] true if the operation is successful
    def remove_from_index
      return false unless ::Mebla.context.index_exists? # only try to index if the index exists      
      
      ::Mebla.log("Removing #{self.class.slingshot_type_name} with id: #{self.id.to_s}", :debug)

      # Delete the document
      response = Slingshot::Configuration.client.delete "#{::Mebla::Configuration.instance.url}/#{::Mebla.context.slingshot_index_name}/#{self.class.slingshot_type_name}/#{self.id.to_s}"
      
      ::Mebla.log("Response for removing #{self.class.slingshot_type_name}: #{response.to_s}", :debug)
      
      # Refresh the index
      ::Mebla.context.refresh_index
      return true
    rescue => error
      raise_synchronization_exception(error)
      
      return false
    end
    
    # Raises synchronization exception in either #add_to_index or #remove_from_index
    def raise_synchronization_exception(error)
      exception_message = "#{self.class.slingshot_type_name} synchronization failed with the following error: #{error.message}"
      if self.class.whiny_indexing
        # Whine when mebla is not able to synchronize
        raise ::Mebla::Errors::MeblaSynchronizationException.new(exception_message)
      else
        # Whining is not allowed, silently log the exception
        ::Mebla.log(exception_message, :warn)
      end
    end
  end
end