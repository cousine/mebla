# A wrapper for slingshot  elastic-search adapter for Mongoid
module Mebla
  # Represents the parent module for all errors in Mebla
  module Errors
    autoload :MeblaError, 'mebla/errors/mebla_error'
    autoload :MeblaFatal, 'mebla/errors/mebla_fatal'
    autoload :MeblaConfigurationException, 'mebla/errors/mebla_configuration_exception'
    autoload :MeblaIndexException, 'mebla/errors/mebla_index_exception'
    autoload :MeblaSynchronizationException, 'mebla/errors/mebla_synchronization_exception'
  end
end