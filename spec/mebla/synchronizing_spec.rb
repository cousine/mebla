require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Mebla" do  
  describe "synchronizing" do
    before(:each) do
      Mebla.context.rebuild_index
      MongoidAlpha.create! :name => "Testing index", :value => 1, :cost => 2.0
    end
    
    it "should index new documents automatically" do
      mdocument = MongoidAlpha.first
      lambda {Mebla.context.slingshot_index.retrieve(:mongoid_alpha, mdocument.id.to_s)}.should_not raise_error
    end
    
    it "should remove deleted documents from index automatically" do
      mdocument = MongoidAlpha.first
      doc_id = mdocument.id.to_s
      mdocument.destroy
      
      lambda {MongoidAlpha.slingshot_index.retrieve(:mongoid_alpha, doc_id)}.should raise_error
    end
    
    it "should update the index automatically when a document is updated" do      
      udocument = MongoidAlpha.first
      udocument.update_attributes(:cost => 3.1).should == true
      
      result = Mebla.context.slingshot_index.retrieve(:mongoid_alpha, udocument.id.to_s)
      result[:cost].should == 3.1
    end    
  end
  
  describe "sub classes" do
    before(:each) do
      Mebla.context.rebuild_index      
      MongoidTheta.create! :extra => "Is this indexed?"
    end
    
    it "should index sub-classed documents automatically under the sub-class type" do
      mdocument = MongoidTheta.first
      lambda {Mebla.context.slingshot_index.retrieve(:mongoid_theta, mdocument.id.to_s)}.should_not raise_error
    end
    
     it "should index sub-classed documents automatically and correctly" do
      pdocument = MongoidTheta.first
      result = Mebla.context.slingshot_index.retrieve(:mongoid_theta, pdocument.id.to_s)
      result[:extra].should == "Is this indexed?"      
    end
  end
  
  describe "documents with indexed method fields" do
    before(:each) do
      Mebla.context.rebuild_index
      MongoidPi.create! :name => "Testing indexing methods"
    end
    
    it "should index method" do
      pdocument = MongoidPi.first
      
      lambda {Mebla.context.slingshot_index.retrieve(:mongoid_pi, pdocument.id.to_s)}.should_not raise_error
    end
    
     it "should index method fields documents automatically and correctly" do
      pdocument = MongoidPi.first
      result = Mebla.context.slingshot_index.retrieve(:mongoid_pi, pdocument.id.to_s)
      result[:does_smth].should == "returns smth"
    end
  end
  
  describe "array fields documents" do
    it "should index array fields and retrieve them correctly" do
      Mebla.context.rebuild_index
      zdocument = MongoidZeta.create :name => "Document with array", :an_array => [:index, :index2, :index2]
      
      lambda {Mebla.context.slingshot_index.retrieve(:mongoid_zeta, zdocument.id.to_s)}.should_not raise_error
    end
    
    it "should index array fields and retrieve them correctly" do
      Mebla.context.rebuild_index
      zdocument = MongoidZeta.create :name => "Document with array", :an_array => [:index, :index2, :index2]
      
      lambda {Mebla.context.slingshot_index.retrieve(:mongoid_zeta, zdocument.id.to_s)}.should_not raise_error
    end
  end
  
  describe "embedded documents" do
    before(:each) do
      Mebla.context.rebuild_index
      beta = MongoidBeta.create! :name => "Embedor parent"
      beta.mongoid_gammas.create :name => "Embedded", :value => 1
    end
    
    it "should index embedded documents automatically and link to the parent" do
      mdocument = MongoidBeta.first.mongoid_gammas.first
      lambda {
        Slingshot::Configuration.client.get "#{Mebla::Configuration.instance.url}/#{Mebla.context.slingshot_index_name}/mongoid_gamma/#{mdocument.id.to_s}?routing=#{mdocument.mongoid_beta.id.to_s}"
      }.should_not raise_error
    end
  end
end