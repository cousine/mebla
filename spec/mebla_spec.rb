require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Mebla" do
  describe "loading" do
    !(defined?(Mongoid).nil?).should == true
    !(defined?(Slingshot).nil?).should == true
    !(defined?(Configuration).nil?).should == true
    !(defined?(Context).nil?).should == true
    !(defined?(LogSubscriber).nil?).should == true
    !(defined?(ResultSet).nil?).should == true
    !(defined?(Errors).nil?).should == true
    !(defined?(Mongoid::Mebla).nil?).should == true
  end
  
  describe "configuration" do
    it "should hold the correct data" do
      Mebla::Configuration.instance.index.should == "mebla"
      Mebla::Configuration.instance.host.should == "localhost"
      Mebla::Configuration.instance.port.should == 9200
      Mebla::Configuration.instance.logger.nil?.should == false
    end
    
    it "url should return a valid url based on the host and port" do
      Mebla::Configuration.instance.url.should == "http://localhost:9200"
    end
  end
end
