require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Mebla" do
  describe "searching" do    
    before(:each) do
      Mebla.context.rebuild_index
      MongoidAlpha.create! :name => "Testing index", :value => 1, :cost => 2.0
    end
    
    it "should search and return the only relevant result" do
      results=MongoidAlpha.search do 
        query { string "name: Testing index" }
      end          
      
      results.count.should == 1          
    end
    
    it "should search and return the only relevant result, and cast it into the correct class type" do
      results=MongoidAlpha.search do 
        query { string "name: Testing index" }
      end 
            
      results.first.class.should == MongoidAlpha
    end
    
    describe "multiple types" do
      before(:each) do
        MongoidBeta.create! :name => "Testing index"
      end
      
      it "should search and return all results of all class types" do        
        results=Mebla.search do 
          query { string "name: Testing index" }
        end 
        
        results.count.should == 2
        (results.each.collect{|e| e.class} & [MongoidAlpha, MongoidBeta]).should == [MongoidAlpha, MongoidBeta]
      end
      
      it "should search and return only results from the searched class type" do        
        results=MongoidAlpha.search do 
          query { string "name: Testing index" }
        end 
        
        results.count.should == 1
        results.first.class.should == MongoidAlpha
      end
    end
    
    describe "embedded documents" do
      before(:each) do
        beta = MongoidBeta.create! :name => "Embedor parent"
        beta.mongoid_gammas.create :name => "Embedded", :value => 1
      end
      
      it "should search and return the only relevant result" do
        results=MongoidGamma.search do 
          query { string "name: Embedded" }
        end 
        
        results.count.should == 1
      end
      
      it "should search and return the only relevant result, and cast it into the correct class type" do
        results=MongoidGamma.search do 
          query { string "name: Embedded" }
        end 
        
        results.first.class.should == MongoidGamma
      end
    end
  end  
end