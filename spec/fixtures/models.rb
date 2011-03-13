class MongoidAlpha 
  include Mongoid::Document
  include Mongoid::Mebla
  field :name
  field :value, :type => Integer
  field :cost, :type => Float
  field :hidden
  
  search_in :cost, :value, :name => { :boost => 2.0, :analyzer => 'snowball' }
end

class MongoidBeta
  include Mongoid::Document
  include Mongoid::Mebla
  field :name    
end

class MongoidGamma
  include Mongoid::Document
  include Mongoid::Mebla
  field :name
  field :value, :type => Integer
  field :beta_id, :type => Integer  
end

class MongoidTheta
  include Mongoid::Document
  include Mongoid::Mebla
  field :name
  field :value, :type => Integer
  field :alpha_id, :type => Integer
end