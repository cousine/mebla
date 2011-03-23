class MongoidAlpha 
  include Mongoid::Document
  include Mongoid::Mebla
  field :name
  field :value, :type => Integer
  field :cost, :type => Float
  field :hidden
  
  self.whiny_indexing = true
  
  referenced_in :mongoid_epsilon
  
  search_in :name, :cost, :value
end

class MongoidBeta
  include Mongoid::Document
  include Mongoid::Mebla
  field :name
  
  self.whiny_indexing = true
    
  embeds_many :mongoid_gammas
  
  search_in :name => {:boost => 2.0, :analyzer => 'snowball'}
end

class MongoidTheta < MongoidAlpha
  field :extra  
  
  search_in :extra
end

class MongoidTau < MongoidAlpha
  field :extra2  
end

class MongoidDelta
  include Mongoid::Document
  include Mongoid::Mebla
  field :name
  
  self.whiny_indexing = true  
end

class MongoidOmega < MongoidDelta
  search_in :name
end

class MongoidZeta
  include Mongoid::Document
  include Mongoid::Mebla
  field :name
  field :an_array, :type => Array
  
  search_in :name, :an_array
end

class MongoidGamma
  include Mongoid::Document
  include Mongoid::Mebla
  field :name
  field :value, :type => Integer  
  
  self.whiny_indexing = true
  
  embedded_in :mongoid_beta
  
  search_in :name, :value, :embedded_in => :mongoid_beta
end

class MongoidPi
  include Mongoid::Document
  include Mongoid::Mebla
  field :name
  
  self.whiny_indexing = true
  
  references_one :mongoid_epsilon
  
  search_in :name, :does_smth
  
  def does_smth
    "returns smth"
  end
end

class MongoidEpsilon
  include Mongoid::Document
  include Mongoid::Mebla
  field :name

  self.whiny_indexing = true
  
  referenced_in :mongoid_pi
  references_many :mongoid_alphas
  
  search_in :name, :search_relations => {:mongoid_pi => :name, :mongoid_alphas => [:name, :value]}
end