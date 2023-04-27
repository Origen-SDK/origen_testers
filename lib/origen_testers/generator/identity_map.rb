module OrigenTesters
  module Generator
    class IdentityMap
      def initialize
        @store = {}
        @versions = {}
      end

      def current_version_of(obj)
        map = map_for(obj)
        if map
          map[:replaced_by] || map[:instance]
        else
          obj
        end
      end

      # rubocop:disable Lint/HashCompareByIdentity
      # .object_id is not the "preferred" method
      def map_for(obj)
        @store[obj.object_id]
      end
      # rubocop:enable Lint/HashCompareByIdentity
    end
  end
end
