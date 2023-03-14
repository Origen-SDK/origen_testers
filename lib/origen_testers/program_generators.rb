require 'active_support/concern'
module OrigenTesters
  # Include this module to create an interface that supports multiple tester
  # types.
  #
  # This module will expose generators for all test platforms supported by
  # the Testers plugin.
  module ProgramGenerators
    extend ActiveSupport::Concern
    include Interface

    PLATFORMS = [J750, J750_HPT, UltraFLEX, V93K, UltraFLEXP]

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

    # @api private
    def pre_initialize(options = {})
      _load_generator
    end

    def initialize(options = {})
    end

    def tester
      Origen.tester
    end

    def _load_generator
      if tester.v93k?
        if tester.smt8?
          class << self; include OrigenTesters::V93K_SMT8::Generator; end
        else
          class << self; include OrigenTesters::V93K::Generator; end
        end
      elsif tester.j750_hpt?
        class << self; include OrigenTesters::J750_HPT::Generator; end
      elsif tester.j750?
        class << self; include OrigenTesters::J750::Generator; end
      elsif tester.ultraflex?
        class << self; include OrigenTesters::UltraFLEX::Generator; end
      elsif tester.ultraflexp?
        class << self; include OrigenTesters::UltraFLEXP::Generator; end
      elsif defined? tester.class::TEST_PROGRAM_GENERATOR
        class << self; include tester.class::TEST_PROGRAM_GENERATOR; end
      else
        fail "The OrigenTesters::ProgramGenerators module does not support #{tester.class}!"
      end
    end
  end
end
