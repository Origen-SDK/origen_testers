module OrigenTesters
  module IGXLBasedTester
    class UltraFLEX
      require 'origen_testers/igxl_based_tester/base/flow'
      class Flow < Base::Flow
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/igxl_based_tester/ultraflex/templates/flow.txt.erb"

        SCALES = [:p, :n, :u, :m, :none, :k, :M]

        def on_test(node)
          super
          ins = node.find(:object).value
          if ins.respond_to?(:lo_limit) && (ins.lo_limit || ins.hi_limit) || ins.respond_to?(:lo) && (ins.lo || ins.hi)
            if ins.defer_limits
              completed_lines.last.opcode = 'Test-defer-limits'
            end
            limit = completed_lines.last.dup
            limit.type = :use_limit
            limit.opcode = 'Use-Limit'
            limit.parameter = nil
            if ins.respond_to?(:lo_limit)
              lo = ins.lo_limit
              hi = ins.hi_limit
              if lo.nil?
                lo = ins.lo
              end
              if hi.nil?
                hi = ins.hi
              end
            elsif ins.respond_to?(:lo)
              lo = ins.lo
              hi = ins.hi
            end

            # add allowance for multiple use-limits lines or single line with different TName entry
            if ins.respond_to?(:limit_tname)
              lim_name = ins.limit_tname
            else
              lim_name = nil
            end

            size = 1
            if lo.is_a?(Array)
              size = lo.size if lo.size > size
            end
            if hi.is_a?(Array)
              size = hi.size if hi.size > size
            end
            if lim_name.is_a?(Array)
              size = lim_name.size  if lim_name.size > size
            end

            size.times do |i|
              limit.tnum += 1 if limit.tnum.is_a?(Numeric)
              line = limit.dup

              if lo.is_a?(Array)
                l = lo[i]
              else
                l = lo
              end

              if hi.is_a?(Array)
                h = hi[i]
              else
                h = hi
              end

              if ins.scale
                if ins.scale.is_a?(Array)
                  s = ins.scale[i]
                else
                  s = ins.scale
                end
              else
                unless $tester.ultraflex?
                  s = lowest_scale(scale_of(l), scale_of(h))
                  l = scaled(l, s)
                  h = scaled(h, s)
                end
              end
              line.lolim = l
              line.hilim = h
              line.scale = s unless s == :none
              if ins.units
                if ins.units.is_a?(Array)
                  line.units = ins.units[i]
                else
                  line.units = ins.units
                end
              end

              # update tname if required
              if lim_name
                if lim_name.is_a?(Array)
                  line.tname = lim_name[i]
                else
                  line.tname = lim_name
                end
              end

              completed_lines << line
            end
          end
        end

        # Returns the scale that should be best used to represent the given number, returns
        # nil in the case where the given number is nil
        def scale_of(number)
          if number && number.is_a?(Numeric)
            number = number.abs
            if number >= 1_000_000
              :M
            elsif number >= 1_000
              :k
            elsif number >= 0.1
              :none
            elsif number >= 0.000_1
              :m
            elsif number >= 0.000_000_1
              :u
            elsif number >= 0.000_000_000_1
              :n
            else
              :p
            end
          end
        end

        # Returns the lowest of the two scales
        def lowest_scale(a, b)
          if a == b
            a
          elsif !a
            b
          elsif !b
            a
          else
            if SCALES.index(a) < SCALES.index(b)
              a
            else
              b
            end
          end
        end

        def scaled(number, scale)
          if number
            if number.is_a?(Numeric)
              number = number.to_f
              if scale
                case scale
                when :M
                  number = number / 1_000_000
                when :k
                  number = number / 1_000
                when :m
                  number = number * 1_000
                when :u
                  number = number * 1_000_000
                when :n
                  number = number * 1_000_000_000
                when :p
                  number = number * 1_000_000_000_000
                end
              end
              if number.round(2) == number.to_i.to_f.round(2)
                number.to_i
              else
                number.round(2)
              end
            else
              number
            end
          end
        end
      end
    end
  end
end
