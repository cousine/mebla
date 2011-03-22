require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Mebla" do
  describe "indexing" do
    it "should index existing records" do
      Mebla.context.drop_index
      
      fdocument = nil
      ldocument = nil
      
      MongoidAlpha.without_indexing do
        fdocument = MongoidAlpha.create! :name => "Testing indexing bulkly", :value => 1, :cost => 1.0
        ldocument = MongoidAlpha.create! :name => "Testing indexing bulkly other one", :value => 2, :cost => 2.0
      end
      
      Mebla.context.index_data
      
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
    
    describe "for sub-classed documents" do
      it "should index existing records" do
        Mebla.context.drop_index
        
        theta = nil
        
        MongoidTheta.without_indexing do
          theta = MongoidTheta.create! :extra => "Subclassed parent"
        end
        
        Mebla.context.index_data
        
        lambda {Mebla.context.slingshot_index.retrieve(:mongoid_theta, theta.id.to_s)}.should_not raise_error
      end
      
      it "should not index non searchable subclassed models" do
        Mebla.context.drop_index        
        
        tau = nil
        MongoidAlpha.without_indexing do
          MongoidAlpha.create! :name => "Testing indexing bulkly", :value => 1, :cost => 1.0          
          tau = MongoidTau.create! :extra2 => "Should not be indexed"
        end
        
        lambda {Mebla.context.index_data}.should_not raise_error
        lambda {Mebla.context.slingshot_index.retrieve(:mongoid_tau, tau.id.to_s)}.should raise_error
      end
      
      it "should index only models with defined indecies" do
        Mebla.context.drop_index
        
        theta = nil
        
        MongoidOmega.without_indexing do
          theta = MongoidOmega.create! :name => "Subclassed parent"
        end        
        
        lambda {Mebla.context.index_data}.should_not raise_error
      end
    end
    
    describe "for embedded documents" do
      it "should index existing records" do
        Mebla.context.drop_index
                
        beta = nil
        gamma = nil
        
        MongoidBeta.without_indexing do
          beta = MongoidBeta.create! :name => "Embedor parent"
          MongoidGamma.without_indexing do
            gamma = beta.mongoid_gammas.create :name => "Embedded", :value => 1
          end
        end        
        
        Mebla.context.index_data
        
        lambda {
          Slingshot::Configuration.client.get "#{Mebla::Configuration.instance.url}/#{Mebla.context.slingshot_index_name}/mongoid_gamma/#{gamma.id.to_s}?routing=#{beta.id.to_s}"
        }.should_not raise_error
      end
      
      it "should create the index with proper parent mapping" do      
        mappings = Mebla.context.slingshot_index.mapping["mongoid_gamma"]
        routing = mappings["_routing"]
        parent = mappings["_parent"]
        routing["path"].should == "mongoid_beta_id"        
        parent["type"].should == "mongoid_beta"        
      end
    end
  end
end