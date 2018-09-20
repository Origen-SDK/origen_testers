# Custom node class with some helper for usage after symbolizing.
module OrigenTesters
  module Decompiler
    # Base node
    # @note Can't call this just <code>SyntaxNode</code> since Treetop isn't namespaced to call its own node.
    #   Will result in all nodes being Origen nodes, which isn't what we want.
    class OrigenTestersNode < Treetop::Runtime::SyntaxNode
      CHECK = true
      CLEAN = true
      SYMBOLIZE = true

      def initialize(*args)
        super

        #
        if symbolize?
          @symbols = begin
            if respond_to?(:symbols)
              symbols
            else
              Origen.log.error "Node #{self.class} indicated that it should be symbolized, but did not provide a list of symbols!"
              Origen.log.error 'Please provide a :symbols method that returns an array of symbols.'
              Origen.app.fail! 'OrigenTestersNode: No :symbols method found'
            end
          end
        end

        if symbolize?
          symbols.each do |s|
            define_singleton_method(s) do
              # The symbol can either be a hard-coded value (just an instance variable value), or a process that
              # finds the desired value. The latter is useful if looking at deeper layers in case some kind of post
              # processing needs to edit the tree structure.
              ins = instance_variable_get("@#{s}".to_sym)
              if ins.respond_to?(:call)
                ins.call
              else
                ins
              end
            end

            # Add a setter as well in case post-processing is required
            define_singleton_method("#{s}=".to_sym) do |val|
              instance_variable_set("@#{s}".to_sym, val)
            end
          end
        end

        # Support some built-in node checking to confirm the node is as expected.
        # This is moreso used to check the grammar, but many base nodes will have them as they make grammar debug
        # better. This can be bypassed by overriding the CHECK constant in a child class or by reopening the class.
        check if check?

        # We'll symbolize first in case cleaning moves or clears items.
        # For example, some things may just be syntax/word/number tokens, which are not necessary to keep after the
        # text value is extracted. However, this requires symbolizing first, then cleaing.
        symbolize if symbolize?
        clean if clean?
        check_symbols if symbolize?
      end

      def check?
        self.class::CHECK
      end

      def clean?
        self.class::CLEAN
      end

      def symbolize?
        self.class::SYMBOLIZE
      end

      # Checks and fails the decompilation if the number of elements does not match or meet the number of expected elements.
      def check_element_size(min_or_num, max = nil)
        if max.nil? && (elements.size != min_or_num)
          Origen.log.error 'Error decompiling Pattern.'
          Origen.log.error "Error cleaning #{self.class}."
          Origen.log.error "Expected node to contain exactly #{min_or_num} elements. Node contained exactly #{elements.size} elements."
          Origen.app.fail! message: 'Decompiler: check_element_size_failed!'
        elsif max.nil? && elements.size < min_or_num
          Origen.log.error 'Error decompiling Pattern.'
          Origen.log.error "Error cleaning #{self.class}."
          Origen.log.error "Expected node to contain at least #{min_or_num} elements. Node contained exactly #{elements.size} elements."
          Origen.app.fail! message: 'Decompiler: check_element_size_failed!'
        elsif !max.nil? && (elements.size < min_or_num || elements.size > max)
          Origen.log.error 'Error decompiling Pattern.'
          Origen.log.error "Error cleaning #{self.class}."
          Origen.log.error "Expected node to contain between #{min_or_num} and #{max} elements. Node contained exactly #{elements.size} elements."
          Origen.app.fail! message: 'Decompiler: check_element_size_failed!'
        end
      end

      # Another quick check to make sure non of the symbols are unset.
      def check_symbols
        nil_symbols = symbols.select { |s| send(s).nil? }
        unless nil_symbols.empty?
          Origen.log.error "Error symbolizing node: #{self.class}: nil symbols found: #{nil_symbols.join(',')}"
          Origen.log.error 'These were added as symbol names, but those symbols were not set!'
          Origen.app.fail! message: 'Decompiler: Error symbolizing node: nil symbols found'
        end
      end

      # Checks and fails the decompilation if the given node element does match the expected node element types.
      def check_element(node, expected, options = {})
        unless expected.is_a?(Array)
          expected = [expected]
        end

        unless expected.include?(node.class)
          Origen.log.error 'Error decompiling Pattern.'
          Origen.log.error "Error cleaning #{self.class}."
          Origen.log.error "Expected node type(s): #{expected.join(', ')}."
          Origen.log.error "Received node type: #{node.class}."
          Origen.log.error " Error occurred cleaning index #{options[:index]}" if options.key?(:index)
          Origen.log.error 'See node tree below:'
          puts inspect

          Origen.app.fail! message: 'Decompiler: check_element failed!'
        end
        true
      end

      ### Provide some dummy methods that will fail if not overridden or disabled by the inheriting node.
      ### This will avoid the 'undefined method for ...' errors.

      def symbolize
        Origen.app.fail! message: "Symbolizing of OrigenTestersNode needs to be implemented or disabled by the inheriting class: #{self.class}!"
      end

      def check
        Origen.app.fail! message: "Checking of OrigenTestersNode needs to be implemented or disabled by the inheriting class: #{self.class}!"
      end

      def clean
        Origen.app.fail! message: "Cleaning of OrigenTestersNode needs to be implemented or disabled by the inheriting class: #{self.class}!"
      end

      def delete_elements_at(*indexes)
        elements.delete_if.with_index { |n, i| indexes.include?(i) }
      end
    end

    # General purpose list node. For grammar rules that resemble:
    # <value>? (<separator> <value>)*
    # Its easy to build a general case for this.
    # These are able to find one or values where each value is delimited by the separator.
    # e.g.: 'TDI TMS TDO' -> word (' ' word)
    #       'i1,i2,i3'    -> word (',' word)
    # For these types of nodes, the result wil always be:
    #   ValueNode_1
    #   SyntaxNode
    #     SeparatorNode
    #     ValueNode_2
    #     SeparatorNode
    #     ValueNode_3
    #     ...
    #     SeparatorNode
    #     ValueNode_n
    # You can use this node class if you want to clean the above to:
    #  ValueNode_1
    #  ValueNode_2
    #  ValueNode_3
    #  ValueNode_n
    # This will automatically symbolize as:
    #  values => [ValueNode_1, ... ValueNode_n]
    # The separator can be any single rule. That rule can be whatever, but it must be a single rule.
    # The default cleaning will lose the separator though, so disable cleaning if the separator information is needed.
    # If the list is empty, the value will be an emtpy array and there will be no elements.
    class OrigenTestersListNode < OrigenTestersNode
      def clean
        if elements[1].elements.empty?
          elements.delete_at(1)
        else
          e = elements.delete_at(1)
          e.elements.each do |_e|
            _e.elements[1].parent = self
            elements << _e.elements[1]
          end
        end

        if elements[0].elements.nil?
          elements.delete_at(0)
        end
      end

      def symbols
        [:values]
      end

      # Check that we only have two SyntaxNodes:
      #  The first of which is a single node
      #  The second of which is a list two-nodes deep.
      #  Since this is general, we aren't concerned with the exact nodes except for SyntaxNode.
      def check
        Origen.log.erro 'DO THIS'
      end

      # Pull each value node out. Each value node doesn't necessarily need to be the same, so leave the node itself alone.
      def symbolize
        @values = []
        (@values << elements[0]) unless elements[0].elements.nil?
        (@values += elements[1].elements.collect { |e| e.elements[1] }) unless elements[1].elements.empty?
      end
    end
  end
end
