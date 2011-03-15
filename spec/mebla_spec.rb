require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Mebla" do
  describe "indexing" do
    it "should index the database" do
      MongoidAlpha.without_indexing do
        MongoidAlpha.create! :name => "Testing indexing bulkly", :value => 1, :cost => 1.0
        MongoidAlpha.create! :name => "Testing indexing bulkly other one", :value => 2, :cost => 2.0
      end
      
      Mebla::Context.instance.index_data      
      
      fdocument = MongoidAlpha.first
      ldocument = MongoidAlpha.last
      
      lambda {MongoidAlpha.slingshot_index.retrieve(:mongoid_alpha, fdocument.id.to_s)}.should_not raise_error
      lambda {MongoidAlpha.slingshot_index.retrieve(:mongoid_alpha, ldocument.id.to_s)}.should_not raise_error
    end

    after(:all) do
      MongoidAlpha.drop_index
    end
  end
  
  describe "runtime" do
    before(:all) do
      MongoidAlpha.create_index
    end
  
    describe "indecies" do
      it "should delete the existing index and create a new one" do
        MongoidAlpha.rebuild_index.should_not == false
      end
    end
    
    describe "synchronization" do
      before(:each) do
        MongoidAlpha.rebuild_index
        MongoidAlpha.create! :name => "Testing index", :value => 1, :cost => 2.0
      end
      
      it "should index new documents automatically" do
        mdocument = MongoidAlpha.first
        lambda {MongoidAlpha.slingshot_index.retrieve(:mongoid_alpha, mdocument.id.to_s)}.should_not raise_error
      end
      
      it "should remove deleted documents from index automatically" do
        mdocument = MongoidAlpha.first
        doc_id = mdocument.id.to_s
        mdocument.destroy
        
        lambda {MongoidAlpha.slingshot_index.retrieve(:mongoid_alpha, doc_id)}.should raise_error
      end
      
      it "should update the index automatically when a document is updated" do      
        udocument = MongoidAlpha.first
        udocument.update_attributes(:cost => 3.1)
        
        result = MongoidAlpha.slingshot_index.retrieve(:mongoid_alpha, udocument.id.to_s)
        result[:cost].should == 3.1
      end
    end
  end
  
  after(:all) do
    MongoidAlpha.drop_index
  end
end
