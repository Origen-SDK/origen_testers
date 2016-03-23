require 'active_support/concern'
module OrigenTesters
  # Include this module to create an interface that supports multiple tester
  # types.
  #
  # This module will expose generators for all test platforms supported by
  # the Testers plugin.
  module ProgramGenerators
    extend ActiveSupport::Concern

    PLATFORMS = [J750, J750_HPT, UltraFLEX, V93K]

    included do
      Origen.add_interface(self)
    end

    module ClassMethods
      # Ensures that the correct generator is loaded before initialize is called
      def new(*args, &block)
        x = allocate
        x._load_generator
        x.send(:initialize, *args, &block)
        x
      end

      # Returns true if the interface class supports the
      # given tester instance
      def supports?(tester_instance)
        PLATFORMS.include?(tester_instance.class)
      end
    end

    def initialize(options = {})
    end

    def tester
      Origen.tester
    end

    def _load_generator
      if tester.v93k?
        class << self; include OrigenTesters::V93K::Generator; end
      elsif tester.j750_hpt?
        class << self; include OrigenTesters::J750_HPT::Generator; end
      elsif tester.j750?
        class << self; include OrigenTesters::J750::Generator; end
      elsif tester.ultraflex?
        class << self; include OrigenTesters::UltraFLEX::Generator; end
      else
        fail "The Testers::ProgramGenerators module does not support #{tester.class}!"
      end
    end
  end
end
