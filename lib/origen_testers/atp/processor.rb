require 'ast'
module OrigenTesters::ATP
  # The base processor, this provides a default handler for
  # all node types and will not make any changes to the AST,
  # i.e. an equivalent AST will be returned by the process method.
  #
  # Child classes of this should be used to implement additional
  # processors to modify or otherwise work with the AST.
  #
  # @see http://www.rubydoc.info/gems/ast/2.0.0/AST/Processor
  class Processor
    include ::AST::Processor::Mixin

    def run(node)
      process(node)
    end

    def process(node)
      if node.respond_to?(:to_ast)
        super(node)
      else
        node
      end
    end

    # Some of our processors remove a wrapping node from the AST, returning
    # a node of type :inline containing the children which should be inlined.
    # Here we override the default version of this method to deal with handlers
    # that return an inline node in place of a regular node.
    def process_all(nodes)
      results = []
      nodes.to_a.each do |node|
        n = process(node)
        if n.respond_to?(:type) && n.type == :inline
          results += n.children
        else
          results << n unless n.respond_to?(:type) && n.type == :remove
        end
      end
      results
    end

    def remove_globals(results, nodes)
      nodes.to_a.each do |node|
        n = process(node)
        if n.respond_to?(:type) && n.type == :global
          results.delete(n.to_a[0].value)
        end
      end
      results
    end

    def handler_missing(node)
      node.updated(nil, process_all(node.children))
    end

    def extract_volatiles(flow)
      @volatiles = {}
      if v = flow.find(:volatile)
        @volatiles[:flags] = Array(v.find_all(:flag)).map(&:value)
      end
    end

    def volatile_flags
      unless @volatiles
        fail 'You must first call extract_volatiles(node) from your on_flow hander method'
      end
      @volatiles[:flags] || []
    end

    # Returns true if the given flag name has been marked as volatile
    def volatile?(flag)
      result = volatile_flags.any? { |f| clean_flag(f) == clean_flag(flag) }
      result
    end

    def extract_globals(flow)
      @globals = {}
      if v = flow.find(:global)
        @globals[:flags] = Array(v.find_all(:flag)).map(&:value)
      end
    end

    def global_flags
      unless @globals
        fail 'You must first call extract_volatiles(node) from your on_flow hander method'
      end
      @globals[:flags] || []
    end

    # Returns true if the given flag name has been marked as volatile
    def global?(flag)
      result = global_flags.any? { |f| clean_flag(f) == clean_flag(flag) }
      result
    end

    def clean_flag(flag)
      flag = flag.dup.to_s
      flag[0] = '' if flag[0] == '$'
      flag.downcase
    end
  end
end
