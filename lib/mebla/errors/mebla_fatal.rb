# A wrapper for slingshot  elastic-search adapter for Mongoid
module Mebla
  # Represents the parent module for all errors in Mebla
  module Errors
    # Default parent Mebla error for all custom fatal errors.
    class MeblaFatal < ::StandardError
      def initialize(message)
        super message
        ::ActiveSupport::Notifications.
          instrument('mebla_fatal.mebla', :message => message)
      end
    end  
  end
end
