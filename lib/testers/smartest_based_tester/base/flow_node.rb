module Testers
  module SmartestBasedTester
    class Base
      class FlowNode
        attr_accessor :type, :id, :rendered, :parent, :deleted
        alias_method :rendered?, :rendered
        alias_method :deleted?, :deleted
        attr_reader :flow

        TYPES = [:run, :run_and_branch, :print, :print_to_datalog, :good_bin, :bad_bin, :group,
                 :assign_value, :if_then
                ]

        ATTRS = {
          good_bin:         {
            soft_bin:      nil,
            soft_bin_desc: nil,
            bin:           nil,
            bin_desc:      nil,
            bin_type:      :good,
            reprobe:       false,
            color:         :green,
            overon:        true
          },
          bad_bin:          {
            soft_bin:      nil,
            soft_bin_desc: 'fail',
            bin:           nil,
            bin_desc:      nil,
            bin_type:      :bad,
            reprobe:       false,
            color:         :red,
            overon:        true
          },
          run:              {
            nodes:      [],
            else_nodes: [],
            test_suite: nil,
            id:         nil
          },
          run_and_branch:   {
            nodes:      [],
            else_nodes: [],
            test_suite: nil,
            id:         nil
          },
          if_then:          {
            condition:  nil,
            nodes:      [],
            else_nodes: []
          },
          print:            {
            value: nil
          },
          print_to_datalog: {
            value: nil
          },
          group:            {
            name:    nil,
            nodes:   [],
            comment: nil,
            bypass:  nil
          },
          assign_value:     {
            variable: nil,
            value:    nil
          }
        }

        ALIASES = {
          good_bin: {
            sbin:    :soft_bin,
            softbin: :soft_bin
          },
          bad_bin:  {
            sbin:    :soft_bin,
            softbin: :soft_bin
          }
        }

        def parent
          @parent || flow.collection
        end

        # Call this instead of FlowNode.new, this will return a dedicated object for the given
        # type if one exists, otherwise it will instantiate a generic FlowNode object
        def self.create(flow, type, attrs = {})
          unless TYPES.include?(type)
            fail "Uknown flow node type :#{type}, valid types are #{TYPES.map { |t| ':' + t.to_s }.join(', ')}"
          end
          attrs[:_flow] = flow
          attrs[:called_internally] = true
          FlowNode.new(type, attrs)
        end

        def initialize(type, attrs = {})
          unless attrs.delete(:called_internally)
            fail "Don't use FlowNode.new, use FlowNode.create instead"
          end
          @flow = attrs.delete(:_flow)
          ATTRS[type].each do |attr, default|
            define_singleton_method("#{attr}=") do |v|
              instance_variable_set("@#{attr}", v)
            end
            define_singleton_method("#{attr}") do
              instance_variable_get("@#{attr}")
            end
            send("#{attr}=", default.respond_to?(:each) ? default.dup : default)
          end
          if ALIASES[type]
            ALIASES[type].each do |alias_, attr|
              define_singleton_method("#{alias_}=") do |v|
                send("#{attr}=", v)
              end
              define_singleton_method("#{alias_}") do
                send(attr)
              end
            end
          end
          @type = type
          attrs.each do |k, v|
            send("#{k}=", v) if respond_to?("#{k}=")
          end
        end

        def inspect
          "<#{self.class}:#{object_id} type: #{type}>"
        end

        # This module implements the flow control API for the V93K
        module FlowControlAPI
          def enable
            @enable
          end

          def enable=(val)
            @enable = val
          end
          alias_method :if_enable=, :enable=
          alias_method :if_enabled=, :enable=
          alias_method :enabled=, :enable=

          def unless_enable
            @unless_enable
          end

          def unless_enable=(val)
            @unless_enable = val
          end
          alias_method :unless_enabled=, :unless_enable=

          def if_jobs
            @if_jobs ||= []
          end

          def unless_jobs
            @unless_jobs ||= []
          end

          def if_job=(jobs)
            [jobs].flatten.compact.each do |job|
              job = job.to_s.upcase
              if_jobs << job unless if_jobs.include?(job)
            end
          end
          alias_method :if_jobs=, :if_job=
          alias_method :add_if_jobs, :if_job=
          alias_method :add_if_job, :if_job=

          def unless_job=(jobs)
            [jobs].flatten.compact.each do |job|
              job = job.to_s.upcase
              job.gsub!('!', '')
              unless_jobs << job unless unless_jobs.include?(job)
            end
          end
          alias_method :unless_jobs=, :unless_job=
          alias_method :add_unless_jobs, :unless_job=
          alias_method :add_unless_job, :unless_job=

          # Run the test only if the given flow variable is true
          def flag_true=(var)
            c = "@#{var.to_s.upcase} == 1"
            if type == :if_then && condition == :skip
              self.condition = c
              self
            else
              node = FlowNode.create(flow, :if_then)
              node.parent = parent
              node.condition = c
              node.nodes << self
              # Replace self in the main flow with the conditional node (which includes self
              # in its parent collection)
              parent[parent.index(self)] = node
              flow.replace_relationship_dependent(self, node)
            end
          end

          # Run the test unless the given flow variable is true
          def flag_clear=(var)
            c = "@#{var.to_s.upcase} != 1"
            if type == :if_then && condition == :skip
              self.condition = c
              self
            else
              node = FlowNode.create(flow, :if_then)
              node.parent = parent
              node.condition = c
              node.nodes << self
              # Replace self in the main flow with the conditional node (which includes self
              # in its parent collection)
              parent[parent.index(self)] = node
              flow.replace_relationship_dependent(self, node)
            end
          end

          def continue_on_fail
            if group? || if_then?
              nodes.reject! do |n|
                if n.bin?
                  n.deleted = true
                  parent.delete(n)
                  true
                end
              end
              nodes.each { |n| n.continue_on_fail if n.test? || n.if_then? }
              if if_then?
                else_nodes.reject! do |n|
                  if n.bin?
                    n.deleted = true
                    parent.delete(n)
                    true
                  end
                end
                else_nodes.each { |n| n.continue_on_fail if n.test? || n.if_then? }
              end
            else
              else_nodes.reject! do |n|
                if n.bin?
                  n.deleted = true
                  parent.delete(n)
                  true
                end
              end
            end
          end

          def set_flag_on_fail(id = id)
            var = "#{id}_FAILED"
            if group?
              nodes.each { |n| n.set_flag_on_fail(id) if n.test? || n.if_then? }
            elsif if_then?
              nodes.each { |n| n.set_flag_on_fail(id) if n.test? || n.if_then? }
              else_nodes.each { |n| n.set_flag_on_fail(id) if n.test? || n.if_then? }
            else
              @fail_flags_set ||= []
              unless @fail_flags_set.include?(var)
                flow.flow_control_variables << var
                else_nodes << flow.assign_value(var, 1)
                @fail_flags_set << var
              end
            end
            var
          end

          def set_flag_on_pass(id = id)
            var = "#{id}_PASSED"
            if group?
              nodes.each { |n| n.set_flag_on_pass(id) if n.test? || n.if_then? }
            elsif if_then?
              nodes.each { |n| n.set_flag_on_pass(id) if n.test? || n.if_then? }
              else_nodes.each { |n| n.set_flag_on_pass(id) if n.test? || n.if_then? }
            else
              @pass_flags_set ||= []
              unless @pass_flags_set.include?(var)
                flow.flow_control_variables << var
                nodes << flow.assign_value(var, 1)
                @pass_flags_set << var
              end
            end
            var
          end

          def set_flag_on_ran(id = id)
            var = "#{id}_RAN"
            if group?
              nodes.each { |n| n.set_flag_on_ran(id) if n.test? }
            else
              @ran_flags_set ||= []
              unless @ran_flags_set.include?(var)
                flow.flow_control_variables << var
                nodes << flow.assign_value(var, 1)
                else_nodes << flow.assign_value(var, 1)
                @ran_flags_set << var
              end
            end
            var
          end

          def run_if_all_passed(parent)
          end

          def run_if_any_passed(parent)
          end

          def run_if_all_failed(parent)
          end

          def run_if_any_failed(parent)
          end
        end
        include FlowControlAPI

        def empty?
          return false if type == :run
          if respond_to?(:nodes)
            nodes.each { |n| return false unless n.deleted? || n.rendered? || n.empty? }
            if respond_to?(:else_nodes)
              else_nodes.each { |n| return false unless n.deleted? || n.rendered? || n.empty? }
            end
            true
          end
        end

        def lines(options = {})
          return [] if empty?
          # Convert Run nodes to Run and Branch as required
          if type == :run && (!nodes.empty? || !else_nodes.empty?)
            self.type = :run_and_branch
          end
          case type
          when :good_bin, :bad_bin
            l = ["stop_bin \"#{soft_bin || bin}\", \"#{soft_bin_desc}\", , #{bin_type}, #{reprobe ? 'reprobe' : 'noreprobe'}, #{color}, #{bin}, #{overon ? 'over_on' : 'not_over_on'};"]
          when :print
            l = ["print(\"#{value}\");"]
          when :print_to_datalog
            l = ["print_dl(\"#{value}\");"]
          when :run
            l = ["run(#{test_suite.name});"]
          when :run_and_branch
            l = [
              "run_and_branch(#{test_suite.name})",
              'then',
              '{'
            ]
            nodes.each do |node|
              l << node.lines(indent: 3) unless node.rendered
              node.rendered = true
            end
            l += [
              '}',
              'else',
              '{'
            ]
            else_nodes.each do |node|
              l << node.lines(indent: 3) unless node.rendered
              node.rendered = true
            end
            l << '}'
            l.flatten!

          when :if_then
            c = condition == :skip ? '1' : condition
            l = [
              "if #{c} then",
              '{'
            ]
            nodes.each do |node|
              l << node.lines(indent: 3) unless node.rendered
              node.rendered = true
            end
            l += [
              '}',
              'else',
              '{'
            ]
            else_nodes.each do |node|
              l << node.lines(indent: 3) unless node.rendered
              node.rendered = true
            end
            l << '}'
            l.flatten!

          when :group
            l = ['{']
            nodes.each do |node|
              l << node.lines(indent: 3) unless node.rendered
              node.rendered = true
            end
            l << "}, #{bypass ? 'groupbypass, ' : ''}open,\"#{name}\", \"#{comment}\""
            l.flatten!
          when :assign_value
            l = ["@#{variable.to_s.upcase} = #{value};"]
          else
            fail "Don't know how to render: #{type}"
          end
          if options[:indent]
            l.map! { |line| (' ' * options[:indent]) + line }
          end
          l
        end

        def finalize(options = {})
          case type
          when :good_bin, :bad_bin
            if bin && bin_desc
              flow.hardware_bin_descriptions[bin] = bin_desc
            end
          end

          # Implement job/enable branches
          unless if_jobs.empty?
            condition = if_jobs.map { |j| "@JOB == \"#{j}\"" }.join(' or ')
            node = FlowNode.create(flow, :if_then)
            node.parent = parent
            node.condition = condition
            node.nodes << self
            parent[parent.index(self)] = node
            self.parent = node.nodes
          end
          unless unless_jobs.empty?
            condition = unless_jobs.map { |j| "@JOB != \"#{j}\"" }.join(' and ')
            node = FlowNode.create(flow, :if_then)
            node.parent = parent
            node.condition = condition
            node.nodes << self
            parent[parent.index(self)] = node
            self.parent = node.nodes
          end
          if enable
            condition = "@#{enable.to_s.upcase} == 1"
            node = FlowNode.create(flow, :if_then)
            node.parent = parent
            node.condition = condition
            node.nodes << self
            parent[parent.index(self)] = node
            self.parent = node.nodes
          end
          if unless_enable
            condition = "@#{unless_enable.to_s.upcase} == 1"
            node = FlowNode.create(flow, :if_then)
            node.parent = parent
            node.condition = condition
            node.else_nodes << self
            parent[parent.index(self)] = node
            self.parent = node.else_nodes
          end
        end

        def group?
          type == :group
        end

        def test?
          [:run, :run_and_branch].include?(@type)
        end

        def if_then?
          type == :if_then
        end

        def bin?
          [:stop_bin, :bad_bin].include?(@type)
        end

        def self.platform
          RGen.interface.platform
        end

        def platform
          self.class.platform
        end
      end
    end
  end
end
