# A wrapper for slingshot  elastic-search adapter for Mongoid
module Mebla  
  # Generates the required files for Mebla to function
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    
    # Generates mebla's configuration file
    def generate_configuration
      template "mebla.yml", "config/mebla.yml"
    end
    
    private
    # Returns the rails application name
    # @return [String]
    def app_name
      @app_name ||= defined_app_const_base? ? defined_app_name : File.basename(destination_root)
    end

    # @private
    # Returns the rails application name underscored
    # @return [String]
    def defined_app_name
      defined_app_const_base.underscore
    end

    # @private
    # Returns the application CONSTANT    
    def defined_app_const_base
      Rails.respond_to?(:application) && defined?(Rails::Application) &&
        Rails.application.is_a?(Rails::Application) && Rails.application.class.name.sub(/::Application$/, "")
    end

    alias :defined_app_const_base? :defined_app_const_base    
  end
end