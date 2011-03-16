require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Mebla" do
  describe "configuration" do
    it "should hold the correct data" do
      Mebla::Configuration.instance.index.should == "mebla"
      Mebla::Configuration.instance.host.should == "localhost"
      Mebla::Configuration.instance.port.should == 9200
    end
    
    it "url should return a valid url based on the host and port" do
      Mebla::Configuration.instance.url.should == "http://localhost:9200"
    end
  end
end
