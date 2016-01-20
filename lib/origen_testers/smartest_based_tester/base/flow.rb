module OrigenTesters
  module SmartestBasedTester
    class Base
      class Flow < ATP::Formatter
        include OrigenTesters::Flow

        attr_accessor :test_suites, :test_methods, :pattern_master, :lines, :stack

        def subdirectory
          'testflow'
        end

        def filename
          super.gsub('_flow', '')
        end

        def hardware_bin_descriptions
          @hardware_bin_descriptions ||= {}
        end

        def flow_control_variables
          @flow_control_variables ||= []
        end

        def finalize(options = {})
          super
          test_suites.finalize
          test_methods.finalize
          @indent = 0
          @lines = []
          @stack = { on_fail: [], on_pass: [] }
          process(model.ast)
          flow_control_variables.uniq!
        end

        def line(str)
          @lines << (' ' * @indent * 2) + str
        end

        def on_test(node)
          name = node.find(:object).to_a[0].name
          if node.children.any? { |n| t = n.try(:type); t == :on_fail || t == :on_pass }
            line "run_and_branch(#{name})"
            process_all(node.to_a.reject { |n| t = n.try(:type); t == :on_fail || t == :on_pass })
            line 'then'
            line '{'
            @indent += 1
            on_pass = node.children.find { |n| n.try(:type) == :on_pass }
            if on_pass
              process_all(on_pass)
              stack[:on_pass].each { |n| process_all(n) }
            end
            @indent -= 1
            line '}'
            line 'else'
            line '{'
            @indent += 1
            on_fail = node.children.find { |n| n.try(:type) == :on_fail }
            if on_fail
              with_continue(on_fail.children.any? { |n| n.try(:type) == :continue }) do
                process_all(on_fail)
                stack[:on_fail].each { |n| process_all(n) }
              end
            end
            @indent -= 1
            line '}'
          else
            line "run(#{name});"
          end
        end

        def on_job(node)
          condition = clean_job(node.to_a[0])
          if condition =~ /^!\((.*)\)$/
            condition = Regexp.last_match(1)
            negative = true
          end
          line "if #{condition} then"
          line '{'
          @indent += 1
          process_all(node) unless negative
          @indent -= 1
          line '}'
          line 'else'
          line '{'
          @indent += 1
          process_all(node) if negative
          @indent -= 1
          line '}'
        end

        def on_run_flag(node)
          flag, state, *nodes = *node
          if flag.is_a?(Array)
            condition = flag.map { |f| "@#{f.upcase} == 1" }.join(' or ')
          else
            condition = "@#{flag.upcase} == 1"
          end
          line "if #{condition} then"
          line '{'
          @indent += 1
          process_all(nodes) if state
          @indent -= 1
          line '}'
          line 'else'
          line '{'
          @indent += 1
          process_all(nodes) unless state
          @indent -= 1
          line '}'
        end
        alias_method :on_flow_flag, :on_run_flag

        def on_set_run_flag(node)
          flag = node.value.upcase
          flow_control_variables << flag
          line "@#{flag} = 1;"
        end

        def on_group(node)
          on_fail = node.children.find { |n| n.try(:type) == :on_fail }
          on_pass = node.children.find { |n| n.try(:type) == :on_pass }
          with_continue(on_fail && on_fail.children.any? { |n| n.try(:type) == :continue }) do
            line '{'
            @indent += 1
            stack[:on_fail] << on_fail if on_fail
            stack[:on_pass] << on_pass if on_pass
            process_all(node.find(:members))
            stack[:on_fail].pop if on_fail
            stack[:on_pass].pop if on_pass
            @indent -= 1
            line "}, open,\"#{unique_group_name(node.find(:name).value)}\", \"\""
          end
        end

        def on_set_result(node)
          unless @continue
            bin = node.find(:bin).try(:value)
            sbin = node.find(:softbin).try(:value)
            desc = node.find(:description).try(:value)
            if bin && desc
              hardware_bin_descriptions[bin] ||= desc
            end
            if node.to_a[0] == 'pass'
              line "stop_bin \"#{sbin}\", \"\", , good, noreprobe, green, #{bin}, over_on;"
            else
              line "stop_bin \"#{sbin}\", \"fail\", , bad, noreprobe, red, #{bin}, over_on;"
            end
          end
        end

        def on_log(node)
          line "print_dl(\"#{node.to_a[0]}\");"
        end

        def unique_group_name(name)
          @group_names ||= {}
          if @group_names[name]
            @group_names[name] += 1
            "#{name}_#{@group_names[name]}"
          else
            @group_names[name] = 1
            name
          end
        end

        def clean_job(job)
          if job.try(:type) == :or
            job.to_a.map { |j| clean_job(j) }.join(' or ')
          elsif job.try(:type) == :not
            "!(#{clean_job(job.to_a[0])})"
          else
            "@JOB == \"#{job.upcase}\""
          end
        end

        def with_continue(value)
          orig = @continue
          @continue = true if value
          yield
          @continue = orig
        end

        ## Convenience method that will automatically generate a run and branch if a :bin
        ## option is supplied. If no :bin option is present then it will generate a simple
        ## run entry in the flow.
        # def test(test_suite, options = {})
        #  sbin = options[:sbin] || options[:softbin] || options[:soft_bin]
        #  if (options[:bin] || sbin) && !options[:continue]
        #    node = run_and_branch(test_suite, options)
        #    options.delete(:id)
        #    # Only pass options to configure the bin, don't pass flow control options, those apply to the main
        #    # test only in this case
        #    bin = bad_bin(options[:bin], options.slice(*(FlowNode::ATTRS[:bad_bin].keys + FlowNode::ALIASES[:bad_bin].keys)))
        #    node.else_nodes << bin
        #    node
        #  else
        #    run(test_suite, options)
        #  end
        # end

        ## This module contains methods that correspond to the test flow primitives available
        ## in the palette window of the test flow editor
        # module Palette
        #  def run(test_suite, options = {})
        #    add(:run, { test_suite: test_suite }.merge(options))
        #  end
        #  alias_method :run_test, :run

        #  def run_and_branch(test_suite, options = {})
        #    add(:run_and_branch, { test_suite: test_suite }.merge(options))
        #  end

        #  def good_bin(number, options = {})
        #    add(:good_bin, { bin: number }.merge(options))
        #  end

        #  def bad_bin(number, options = {})
        #    add(:bad_bin, { bin: number }.merge(options))
        #  end

        #  def multi_bin(number, options = {})
        #    fail 'V93K Flow#multi_bin method has not been implemented yet!'
        #  end

        #  def print(msg, options = {})
        #    add(:print, { value: msg }.merge(options))
        #  end

        #  def print_to_datalog(msg, options = {})
        #    add(:print_to_datalog, { value: msg }.merge(options))
        #  end

        #  def assign_value(variable, value, options = {})
        #    add(:assign_value, { variable: variable, value: value }.merge(options))
        #  end

        #  def if_then(condition, options = {})
        #    add(:if_then, { condition: condition }.merge(options))
        #  end

        #  def group(name, options = {})
        #    name = make_unique(:group, name)
        #    g = add(:group, { name: name }.merge(options))
        #    if block_given?
        #      open_groups << g
        #      yield g
        #      open_groups.pop
        #    end
        #    g
        #  end
        # end
        # include Palette

        ## Convenience method to provide similar functionality to enabling a Teradyne flow word/variable
        # def enable_flow_word(variable, options = {})
        #  assign_value(variable, 1, options)
        # end

        # def skip(identifier = nil, options = {})
        #  identifier, options = nil, identifier if identifier.is_a?(Hash)
        #  open_skips << []
        #  yield
        #  nodes = open_skips.pop
        #  s = if_then(:skip, options)
        #  s.else_nodes = nodes
        # end

        # private

        # def add(type, options = {})
        #  options = save_context(options) if [:run, :run_and_branch].include?(type)

        #  # Delete the ID if a test within a group with the same ID to avoid a duplicate ID
        #  # error.
        #  if options[:id]
        #    id = Origen.interface.filter_id(options[:id], options)
        #    options.delete(:id) if group_opened? && open_groups.any? { |g| g.id == id }
        #  end
        #  node = track_relationships(options) do |options|
        #    platform::FlowNode.create(self, type, options)
        #  end
        #  unless Origen.interface.resources_mode?
        #    if skip_opened?
        #      open_skips.last << node
        #      node.parent = open_skips.last
        #    else
        #      if group_opened?
        #        open_groups.last.nodes << node
        #        node.parent = open_groups.last.nodes
        #      else
        #        collection << node
        #      end
        #    end
        #  end
        #  if node.test?
        #    node.test_suite = options[:test_suite]
        #    c = Origen.interface.consume_comments
        #    unless Origen.interface.resources_mode?
        #      Origen.interface.descriptions.add_for_test_usage(node.test_suite.name, Origen.interface.top_level_flow, c)
        #    end
        #  else
        #    Origen.interface.discard_comments
        #  end
        #  node
        # end

        # def open_skips
        #  @open_skips ||= []
        # end

        # def skip_opened?
        #  open_skips.size > 0
        # end

        # def open_groups
        #  @open_groups ||= []
        # end

        # def group_opened?
        #  open_groups.size > 0
        # end

        # def make_unique(type, name, options = {})
        #  @uniques ||= {}
        #  t = @uniques[type] ||= {}
        #  t[name] ||= 0
        #  t[name] += 1
        #  if t[name] == 1
        #    name
        #  else
        #    "#{name}_#{t[name]}"
        #  end
        # end
      end
    end
  end
end
