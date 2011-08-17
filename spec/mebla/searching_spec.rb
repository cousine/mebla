require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Mebla" do
  describe "searching" do    
    before(:each) do
      Mebla.context.rebuild_index
      MongoidAlpha.create! :name => "Testing index", :value => 1, :cost => 2.0
    end
    
    it "should search and return the only relevant result" do
      results=MongoidAlpha.search "name: Testing index"      
      
      results.total.should == 1          
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
        
        results.total.should == 1
      end
    end
    
    describe "documents with indexed methods" do
      before(:each) do
        Mebla.context.rebuild_index
        MongoidPi.create! :name => "Document with an indexed method"
      end
      
      it "should search within indexed methods" do
        results = MongoidPi.search "returns smth"
        
        results.total.should == 1
      end
    end
    
    describe "documents with indexed relation fields" do
      before(:each) do
        Mebla.context.rebuild_index
        pi = MongoidPi.create! :name => "A pi"
        alpha = MongoidAlpha.create! :name => "Testing index", :value => 1, :cost => 2.0
        epsilon = pi.create_mongoid_epsilon :name => "epsilon"#, :mongoid_alphas => [alpha] # currently there is a bug in setting the relation like this while creating the document
        epsilon.mongoid_alphas << alpha
        epsilon.save # another bug; mongoid doesn't raise the save callbacks for `<<` method
      end
      
      it "should search within indexed fields from the relations" do
        results = MongoidEpsilon.search "Testing index"
        
        results.total.should == 1        
      end
    end
    
    describe "multiple types" do
      before(:each) do
        MongoidBeta.create! :name => "Testing index"
      end
      
      it "should search and return all results of all class types" do        
        results=Mebla.search  "name: Testing index"        
        
        results.total.should == 2
        (results.each.collect{|e| e.class} & [MongoidAlpha, MongoidBeta]).should =~ [MongoidAlpha, MongoidBeta]
      end
      
      it "should search and return only results from the searched class type" do        
        results=MongoidAlpha.search "name: Testing index"        
        
        results.total.should == 1
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
        
        results.total.should == 1
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
        Mebla.search.term(:name, "index").total.should == 2
      end
      
      it "should search and only return results matching the terms defined" do
        Mebla.search.terms(:name, ["index", "map"]).total.should == 3
      end
      
      it "should search and filter results according to the filters defined" do
        Mebla.search.terms(:name, ["index", "map"]).only(:value => [1]).total.should == 1
      end
      
      it "should search and return results along with facets" do
        results = Mebla.search.terms(:name, ["index", "map"]).facet("values", :value)        
        results.facets["values"]["terms"].count.should == 2
      end
    end
  end  
end