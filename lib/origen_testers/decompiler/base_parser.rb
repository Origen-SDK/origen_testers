module OrigenTesters
  module Decompiler
    module BaseGrammar
      module BaseParser
        def self.metadata
          @metadata ||= {}
        end

        def self.clear_metadata
          @metadata = nil
        end

        def parser
          send(:class_variable_get, :@@parser) || begin
            Origen.log.error "Parent class #{self.class} needs to define the pattern-specific @@parser"
            Origen.log.error 'This will be something like: @@parser = AtpParser.new'
            Origen.app.fail! message: 'No class variable @@parser found'
          end
        end

        def tree
          send(:class_variable_get, :@@tree) || begin
            Origen.log.warning "No parsing has occurred or parsing failed for #{self.class}"
            Origen.log.warning 'Tree will be nil'
          end
        end

        def tree=(tree)
          send(:class_variable_set, :@@tree, tree)
        end

        def parse(data)
          self.tree = nil
          self.tree = parser.parse(data)
          if tree.nil?
            Origen.log.error 'Unable to Parse V93K pattern:'
            Origen.log.error parser.failure_reason
            Origen.log.error parser.failure_line
            Origen.log.error parser.failure_column
            Origen.app.fail!(message: 'Unable to Parse V93K pattern')
          end
          tree
        end
      end
    end
  end
end
