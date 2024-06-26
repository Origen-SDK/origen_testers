module OrigenTesters::ATP
  module FlowAPI
    def atp=(atp)
      @atp = atp
    end

    def atp
      @atp
    end

    ([:test, :bin, :pass, :continue, :cz, :log, :sub_test, :volatile, :add_global_flag, :set_flag, :unset_flag, :add_flag, :set, :enable, :disable, :render,
      :context_changed?, :ids, :describe_bin, :describe_softbin, :describe_soft_bin, :add_auxiliary_flow] +
      OrigenTesters::ATP::Flow::CONDITION_KEYS.keys + OrigenTesters::ATP::Flow::RELATIONAL_OPERATORS).each do |method|
      define_method method do |*args, &block|
        options = args.pop if args.last.is_a?(Hash)
        options ||= {}
        add_meta!(options) if respond_to?(:add_meta!, true)
        add_description!(options) if respond_to?(:add_description!, true)
        args << options
        atp.send(method, *args, &block)
      end
    end

    alias_method :logprint, :log

    def loop(*args, &block)
      if args.empty? && !Origen.interface_loaded?
        super(&block)
      else
        options = args.pop if args.last.is_a?(Hash)
        options ||= {}
        add_meta!(options) if respond_to?(:add_meta!, true)
        add_description!(options) if respond_to?(:add_description!, true)
        args << options
        atp.send(:loop, *args, &block)
      end
    end

    def lo_limit(value, options)
      {
        value:    value,
        rule:     options[:rule] || :gte,
        units:    options[:units],
        selector: options[:selector] || options[:test_mode]
      }
    end

    def hi_limit(value, options)
      {
        value:    value,
        rule:     options[:rule] || :lte,
        units:    options[:units],
        selector: options[:selector] || options[:test_mode]
      }
    end

    def limit(value, options)
      unless options[:rule]
        fail 'You must supply option :rule (e.g. rule: :gt) when calling the limit helper'
      end
      {
        value:    value,
        rule:     options[:rule] || :lt,
        units:    options[:units],
        selector: options[:selector] || options[:test_mode]
      }
    end
  end
end
