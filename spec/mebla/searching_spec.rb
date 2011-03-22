require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Mebla" do
  describe "searching" do    
    before(:each) do
      Mebla.context.rebuild_index
      MongoidAlpha.create! :name => "Testing index", :value => 1, :cost => 2.0
    end
    
    it "should search and return the only relevant result" do
      results=MongoidAlpha.search "name: Testing index"      
      
      results.count.should == 1          
    end
    
    it "should search and return the only relevant result, and cast it into the correct class type" do
      results=MongoidAlpha.search "name: Testing index"
            
      results.first.class.should == MongoidAlpha
    end
    
    describe "documents with arrays" do
      before(:each) do
        Mebla.context.rebuild_index
        MongoidZeta.create! :name => "Document with array", :an_array => [:item, :item2]
      end
      
      it "should return arrays correctly" do
        results = MongoidZeta.search "Document with array"
        
        results.first.an_array.class.should == Array
      end
      
      it "should search within arrays" do
        results = MongoidZeta.search "item2"
        
        results.count.should == 1
      end
    end
    
    describe "multiple types" do
      before(:each) do
        MongoidBeta.create! :name => "Testing index"
      end
      
      it "should search and return all results of all class types" do        
        results=Mebla.search  "name: Testing index"        
        
        results.count.should == 2
        (results.each.collect{|e| e.class} & [MongoidAlpha, MongoidBeta]).should =~ [MongoidAlpha, MongoidBeta]
      end
      
      it "should search and return only results from the searched class type" do        
        results=MongoidAlpha.search "name: Testing index"        
        
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
        results=MongoidGamma.search "name: Embedded"        
        
        results.count.should == 1
      end
      
      it "should search and return the only relevant result, and cast it into the correct class type" do
        results=MongoidGamma.search "name: Embedded"        
        
        results.first.class.should == MongoidGamma
      end
    end
    
    describe "with options" do
      before(:each) do        
        beta = MongoidBeta.create! :name => "Different map"
        beta.mongoid_gammas.create :name => "Testing index 2", :value => 2
      end
      
      it "should sort descending according to the criteria defined" do
        Mebla.search("Testing index").desc(:value).first.class.should == MongoidGamma
      end
      
      it "should sort ascending according to the criteria defined" do
        Mebla.search("Testing index").asc(:value).first.class.should == MongoidAlpha
      end
      
      it "should search and only return results matching the term defined" do
        Mebla.search.term(:name, "index").count.should == 2
      end
      
      it "should search and only return results matching the terms defined" do
        Mebla.search.terms(:name, ["index", "map"]).count.should == 3
      end
      
      it "should search and filter results according to the filters defined" do
        Mebla.search.terms(:name, ["index", "map"]).only(:value => [1]).count.should == 1
      end
      
      it "should search and return results along with facets" do
        results = Mebla.search.terms(:name, ["index", "map"]).facet("values", :value)        
        results.facets["values"]["terms"].count.should == 2
      end
    end
  end  
end