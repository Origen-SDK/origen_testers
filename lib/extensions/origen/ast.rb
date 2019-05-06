require 'origen'
require 'ast'

module Origen
  module AST
    module Processor
      class Base
        include ::AST::Processor::Mixin

        attr_reader :platform_nodes

        def self.inherited(subclass)
          if subclass.const_defined?(:PLATFORM_NODES)
            subclass.const_get(:PLATFORM_NODES).each do |n|
              subclass.define_instance_method(n) do
                instance_variable_get(":@#{n}")
              end
            end
          end
        end

        def initialize(*args)
          unless platform_nodes.empty?
            platform_nodes.each do |n|
              define_singleton_method(n) do
                instance_variable_get("@#{n}".to_sym)
              end
            end
          end
        end

        def platform_nodes
          self.class.const_defined?(:PLATFORM_NODES) ? self.class.const_get(:PLATFORM_NODES) : []
        end

        def handler_missing(node)
          node.updated(nil, process_all(node.children))
        end

        def process(node)
          return node unless node.respond_to?(:to_ast)
          super
        end
      end
    end
  end
end
