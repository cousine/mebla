require 'mebla'
require 'rails'

# @private
module Mebla
  # @private
  class Railtie < Rails::Railtie
    # Configuration
     initializer "mebla.set_configs" do |app|
      Mebla.configure do |config|
        # Open logfile
        config.logger = Logger.new(
          open("#{Dir.pwd}/logs/#{Rails.env}.mebla.log", "a")
        )
        # Setup the log level
        config.logger.level = case app.config.log_level
          when :info
            Logger::INFO
          when :warn
            Logger::WARN          
          when :error
            Logger::ERROR
          when :fatal
            Logger::FATAL
          else
            Logger::DEBUG
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