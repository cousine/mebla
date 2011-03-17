# A wrapper for slingshot  elastic-search adapter for Mongoid
module Mebla
  # Represents the parent module for all errors in Mebla
  module Errors
    # Thrown when configuration fails
    # @note this is a fatal exception
    class MeblaIndexException < MeblaFatal
    end  
  end
end
