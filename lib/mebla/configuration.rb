require 'erb'
require 'singleton'

# @private
module Mebla
  # Parses the configuration file and holds important configuration attributes  
  class Configuration
    include Singleton
    
    attr_reader :log_dir
    attr_accessor :index, :host, :port, :logger
    
    # @private
    def initialize
      @log_dir = "#{Dir.pwd}/tmp/log"
      parse_config      
      
      # Setup defaults
      @index ||= "mebla"
      @host ||= "localhost"
      @port ||= 9200
      
      make_tmp_dir
      @logger = ActiveSupport::BufferedLogger.new(
        open("#{@log_dir}/mebla.log", "a")
      )
      @logger.level = ActiveSupport::BufferedLogger::Severity::DEBUG
      
      setup_logger        
      
      # Setup slingshot
      Slingshot::Configuration.url(self.url)
    end
    
    # Sets up the default settings of the logger
    # @return [nil]
    def setup_logger
      @logger.auto_flushing = true      
    end
    
    # Returns the proper url for elasticsearch
    # @return [String] url representation of the configuration options host and port
    def url
      "http://#{@host}:#{@port}"
    end
    
    private    
    # Creates tmp directory if it doesn't exist
    # @return [nil]
    def make_tmp_dir
      FileUtils.mkdir_p @log_dir
      Dir["#{@log_dir}/*"].each do |file|
        FileUtils.rm_rf file
      end
    end
    
    # Loads the configuration file
    # @return [nil]
    def parse_config      
      path = "#{Rails.root}/config/mebla.yml"
      return unless File.exists?(path)
      
      conf = YAML::load(ERB.new(IO.read(path)).result)[Rails.env]
      
      conf.each do |key,value|
        self.send("#{key}=", value) if self.respond_to?("#{key}=")
      end unless conf.nil?
    end
  end
end