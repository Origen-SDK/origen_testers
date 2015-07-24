module Testers
  module Test
    class Block
      attr_accessor :id, :selected

      def initialize(id, owner)
        @id = id
        @selected = false
        @owner = owner
      end

      def select
        @selected = true
      end

      def owner
        @owner
      end
    end
  end
end
