require 'erb'
require 'singleton'

# @private
module Mebla
  # Parses the configuration file and holds important configuration attributes  
  class Configuration
    include Singleton
    
    attr_accessor :index, :host, :port    
    
    # @private
    def initialize
      parse_config

      # Setup defaults
      @index ||= "mebla"
      @host ||= "localhost"
      @port ||= 9200
      
      # Setup slingshot
      Slingshot::Configuration.url(self.url)
    end
    
    # Returns the proper url for elasticsearch
    def url
      "http://#{@host}:#{@port}"
    end
    
    private
    # Loads the configuration file
    # @return [nil]
    def parse_config
      return unless defined?(Rails)
      path = "#{Rails.root}/config/mebla.yml"
      return unless File.exists?(path)
      
      conf = YAML::load(ERB.new(IO.read(path)).result)[Rails.env]
      
      conf.each do |key,value|
        self.send("#{key}=", value) if self.respond_to?("#{key}=")
      end unless conf.nil?
    end
  end
end