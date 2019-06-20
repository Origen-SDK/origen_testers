module OrigenTesters::ATP
  module Processors
    # Makes the AST safe for Marshaling
    class Marshal < Processor
      def on_object(node)
        o = node.value
        if o.is_a?(String)
          meta = { 'Test' => o }
        elsif o.is_a?(Hash)
          meta = o
        elsif o.respond_to?(:to_meta) && o.to_meta && !o.to_meta.empty?
          meta = o.to_meta
        else
          meta = {}
        end
        # The test suite / test instance name
        meta['Test'] ||= o.try(:name)
        meta['Pattern'] ||= o.try(:pattern)
        # The test name column on IG-XL, or the name of a specific instance of a test which shares a common
        # 'Test' name with other tests
        meta['Test Name'] ||= o.try(:test_name) || o.try(:_test_name) || o.try('TestName') || meta['Test']
        # The name of the primary test that is logged by the test instance / test method, if it logs more
        # than one then this is represented by sub_test nodes
        meta['Sub Test Name'] ||= o.try(:sub_test_name) || o.try('SubTestName') || meta['Test']
        node.updated(nil, [meta])
      end

      def on_render(node)
        node.updated(nil, [node.value.to_s])
      end
    end
  end
end
