class MongoidAlpha 
  include Mongoid::Document
  include Mongoid::Mebla
  field :name
  field :value, :type => Integer
  field :cost, :type => Float
  field :hidden
  
  self.whiny_indexing = true
  
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