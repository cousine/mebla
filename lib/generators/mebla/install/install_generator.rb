# @private
module Mebla  
  # @private
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    
    # Generates mebla's configuration file
    def generate_configuration
      template "mebla.yml", "config/mebla.yml"
    end
    
    private
    def app_name
      @app_name ||= defined_app_const_base? ? defined_app_name : File.basename(destination_root)
    end

    def defined_app_name
      defined_app_const_base.underscore
    end

    def defined_app_const_base
      Rails.respond_to?(:application) && defined?(Rails::Application) &&
        Rails.application.is_a?(Rails::Application) && Rails.application.class.name.sub(/::Application$/, "")
      end

    alias :defined_app_const_base? :defined_app_const_base

    def app_const_base
      @app_const_base ||= defined_app_const_base || app_name.gsub(/\W/, '_').squeeze('_').camelize
    end

    def app_const
      @app_const ||= "#{app_const_base}::Application"
    end

    def valid_app_const?
      if app_const =~ /^\d/
        raise Error, "Invalid application name #{app_name}. Please give a name which does not start with numbers."
      elsif RESERVED_NAMES.include?(app_name)
        raise Error, "Invalid application name #{app_name}. Please give a name which does not match one of the reserved rails words."
      elsif Object.const_defined?(app_const_base)
        raise Error, "Invalid application name #{app_name}, constant #{app_const_base} is already in use. Please choose another application name."
      end
    end
  end
end