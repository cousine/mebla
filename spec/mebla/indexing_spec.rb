require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# TODO: Add tests for indexing embedded documents
describe "Mebla" do
  describe "indexing" do
    it "should index the database" do
      Mebla.context.drop_index
      
      MongoidAlpha.without_indexing do
        MongoidAlpha.create! :name => "Testing indexing bulkly", :value => 1, :cost => 1.0
        MongoidAlpha.create! :name => "Testing indexing bulkly other one", :value => 2, :cost => 2.0
      end
      
      Mebla.context.index_data      
      
      fdocument = MongoidAlpha.first
      ldocument = MongoidAlpha.last
      
      lambda {Mebla.context.slingshot_index.retrieve(:mongoid_alpha, fdocument.id.to_s)}.should_not raise_error
      lambda {Mebla.context.slingshot_index.retrieve(:mongoid_alpha, ldocument.id.to_s)}.should_not raise_error
    end
    
    it "should delete the existing index and create a new one" do
      Mebla.context.rebuild_index.should_not == false
    end
      
    it "should create the index with proper mapping" do      
      maps = Mebla.context.slingshot_index.mapping["mongoid_alpha"]["properties"]
      maps["name"]["type"].should == "string"
      maps["value"]["type"].should == "integer"
      maps["cost"]["type"].should == "float"
    end
  end
end