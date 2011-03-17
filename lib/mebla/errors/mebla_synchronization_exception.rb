# A wrapper for slingshot  elastic-search adapter for Mongoid
module Mebla
  # Represents the parent module for all errors in Mebla
  module Errors
    # Thrown when a synchronization operation fails
    class MeblaSynchronizationException < MeblaError      
    end  
  end
end
