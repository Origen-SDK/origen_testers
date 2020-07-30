module OrigenTesters
  module Charz
    class Profile

      attr_accessor :id, :name, :placement, :enables, :flags, :routines, :tests

      def initialize(id, options = {}, &block)
        @id = id
        @id = @id.symbolize unless id.is_a? Symbol
        @name = options[:name] || id
        @tests = []
        options.each { |k, v| instance_variable_set("@#{k}", v) }
        (block.arity < 1 ? (instance_eval(&block)) : block.call(self)) if block_given?
      end

      def generate_charz_tests(options)
        @routines.each do |routine|
          tests << routine.create_test(options)
        end
      end

      def method_missing(m, *args, &block)
        ivar = "@#{m.to_s.gsub('=', '')}"
        ivar_sym = ":#{ivar}"
        if m.to_s =~ /=$/
          define_singleton_method(m) do |val|
            instance_variable_set(ivar, val)
          end
        elsif instance_variables.include? ivar_sym
          instance_variable_get(ivar)
        else
          define_singleton_method(m) do
            instance_variable_get(ivar)
          end
        end
        send(m, *args, &block)
      end

    end
  end
end
