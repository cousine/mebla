# @private
module Mebla  
  # @private
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    
    # Generates mebla's configuration file
    def generate_configuration
      template "mebla.yml", "config/mebla.yml"
    end
  end
end