module OrigenTesters
  module IGXLBasedTester
    class UltraFLEX
      require 'origen_testers/igxl_based_tester/base/flow'
      class Flow < Base::Flow
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/igxl_based_tester/ultraflex/templates/flow.txt.erb"

        def on_test(node)
          super
          ins = node.find(:object).value
          if ins.respond_to?(:meta) && (ins.meta[:lo_limit] || ins.meta[:hi_limit])
            limit = completed_lines.last.dup
            limit.type = :use_limit
            limit.opcode = 'Use-Limit'
            limit.parameter = nil
            limit.lolim = ins.meta[:lo_limit]
            limit.hilim = ins.meta[:hi_limit]
            completed_lines << limit
          end
        end
      end
    end
  end
end
