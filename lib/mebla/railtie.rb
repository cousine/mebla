require 'mebla'
require 'rails'

# A wrapper for slingshot  elastic-search adapter for Mongoid
module Mebla
  # @private
  # Railtie for Mebla
  class Railtie < Rails::Railtie
    # Configuration
     initializer "mebla.set_configs" do |app|
      Mebla.configure do |config|
        # Open logfile
        config.logger = ActiveSupport::BufferedLogger.new(
          open("#{Dir.pwd}/log/#{Rails.env}.mebla.log", "a")
        )
        # Setup the log level
        config.logger.level = case app.config.log_level
          when :info
            ActiveSupport::BufferedLogger::Severity::INFO
          when :warn
            ActiveSupport::BufferedLogger::Severity::WARN          
          when :error
            ActiveSupport::BufferedLogger::Severity::ERROR
          when :fatal
            ActiveSupport::BufferedLogger::Severity::FATAL
          else
            ActiveSupport::BufferedLogger::Severity::DEBUG
          end
          
        config.setup_logger
      end
    end    
    
    # Rake tasks
    rake_tasks do
      load File.expand_path('../tasks.rb', __FILE__)
    end
  end
end