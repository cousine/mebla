class MeblaHelper
  attr_accessor :host, :username, :password
  
  def initialize
    @host = "localhost"
    @username = ""
    @password = ""
    
    if File.exist?("spec/fixtures/mongoid.yml")
      config    = YAML.load(File.open("spec/fixtures/mongoid.yml"))
      @host     = config["host"]
      @username = config["username"]
      @password = config["password"]      
    end
  end
  
  def setup_mongoid
    Mongoid.configure do |config|
      name = "mebla"
      host = @host
      username = @username
      password = @password
      config.allow_dynamic_fields = false
      config.master = Mongo::Connection.new.db(name)        
    end
  end
end