require 'ast'
module OrigenTesters::ATP
  module AST
    class Node < ::AST::Node
      attr_reader :file, :line_number, :description, :properties
      attr_accessor :id

      def initialize(type, children = [], properties = {})
        @properties = properties
        # Always use strings instead of symbols in the AST, makes serializing
        # back and forward to a string easier
        children = children.map { |c| c.is_a?(Symbol) ? c.to_s : c }
        super type, children, properties
      end

      def _dump(depth)
        # this strips the @strip information from the instance
        # d = { type: type, children: children, properties: properties }
        d = { klass:       self.class,
              id:          id,
              file:        file,
              line_number: line_number,
              description: description,
              type:        type,
              children:    Processors::Marshal.new.process_all(children),
              properties:  properties }
        Marshal.dump(d, depth)
      end

      def self._load(str)
        d = Marshal.load(str)
        p = d[:properties]
        p[:id] = d[:id]
        p[:file] = d[:file]
        p[:line_number] = d[:line_number]
        p[:description] = d[:description]
        n = d[:klass].new(d[:type], d[:children], p)
        n
      end

      def source
        if file
          "#{file}:#{line_number}"
        else
          '<Sorry, lost the source file info, please include an example if you report as a bug>'
        end
      end

      # Returns true if the node carries source file data, retrieve it via the source method
      def has_source?
        !!file
      end

      # Create a new node from the given S-expression (a string)
      def self.from_sexp(sexp)
        @parser ||= Parser.new
        @parser.string_to_ast(sexp)
      end

      # Adds an empty node of the given type to the children unless another
      # node of the same type is already present
      def ensure_node_present(type, *child_nodes)
        if children.any? { |n| n.type == type }
          self
        else
          if !child_nodes.empty?
            node = updated(type, child_nodes)
          else
            node = updated(type, [])
          end
          updated(nil, children + [node])
        end
      end

      # Returns the value at the root of an AST node like this:
      #
      #   node # => (module-def
      #               (module-name
      #                 (SCALAR-ID "Instrument"))
      #
      #   node.value  # => "Instrument"
      #
      # No error checking is done and the caller is responsible for calling
      # this only on compatible nodes
      def value
        val = children.first
        val = val.children.first while val.respond_to?(:children)
        val
      end

      # Add the given nodes to the children
      def add(*nodes)
        updated(nil, children + nodes)
      end

      # Remove the given nodes (or types) from the children
      def remove(*nodes)
        nodes = nodes.map do |node|
          if node.is_a?(Symbol)
            find_all(node)
          else
            node
          end
        end.flatten.compact
        updated(nil, children - nodes)
      end

      # Returns the first child node of the given type(s) that is found
      def find(*types)
        children.find { |c| types.include?(c.try(:type)) }
      end

      # Returns an array containing all child nodes of the given type(s), by default only considering
      # the immediate children of the node on which this was called.
      #
      # To find all children of the given type by recursively searching through all child nodes, pass
      # recursive: true when calling this method.
      def find_all(*types)
        options = types.pop if types.last.is_a?(Hash)
        options ||= {}
        if options[:recursive]
          Extractor.new.process(self, types)
        else
          children.select { |c| types.include?(c.try(:type)) }
        end
      end

      # Returns an array containing all flags which are set within the given node
      def set_flags
        Processors::ExtractSetFlags.new.run(self)
      end

      # Returns a copy of node with any sub-flow nodes removed
      def excluding_sub_flows
        Processors::SubFlowRemover.new.run(self)
      end

      # Returns true if the node contains any nodes of the given type(s) or if any
      # of its children do.
      # To consider only direct children of this node use: node.find_all(*types).empty?
      def contains?(*types)
        !Extractor.new.process(self, types).empty?
      end
    end
  end
end
