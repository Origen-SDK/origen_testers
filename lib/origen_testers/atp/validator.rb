require 'ast'
module OrigenTesters::ATP
  class Validator < Processor
    attr_reader :flow

    def self.testing=(value)
      @testing = value
    end

    def self.testing
      @testing
    end

    def initialize(flow)
      @flow = flow
    end

    def process(node)
      if @top_level_called
        super
      else
        @top_level_called = true
        setup
        super(node)
        unless @testing
          exit 1 if on_completion
        end
      end
    end

    # For test purposes, returns true if validation failed rather
    # than exiting the process
    def test_process(node)
      @testing = true
      process(node)
      on_completion
    end

    def setup
    end

    def error(message)
      # This is a hack to make the specs pass, for some reason RSpec
      # seems to be swallowing the Origen log output after the first
      # test that generates an error
      if Validator.testing
        puts message
      else
        Origen.log.error(message)
      end
    end
  end
end
