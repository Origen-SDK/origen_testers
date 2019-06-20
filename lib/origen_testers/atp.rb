module OrigenTesters::ATP
  autoload :Program, 'origen_testers/atp/program'
  autoload :Flow, 'origen_testers/atp/flow'
  autoload :Processor, 'origen_testers/atp/processor'
  autoload :Validator, 'origen_testers/atp/validator'
  autoload :Runner, 'origen_testers/atp/runner'
  autoload :Formatter, 'origen_testers/atp/formatter'
  autoload :Parser, 'origen_testers/atp/parser'
  autoload :FlowAPI, 'origen_testers/atp/flow_api'

  module AST
    autoload :Node, 'origen_testers/atp/ast/node'
    autoload :Extractor, 'origen_testers/atp/ast/extractor'

    # This is a shim to help backwards compatibility with ATP v0
    module Builder
      class LazyObject < ::BasicObject
        def initialize(&callable)
          @callable = callable
        end

        def __target_object__
          @__target_object__ ||= @callable.call
        end

        def method_missing(method_name, *args, &block)
          __target_object__.send(method_name, *args, &block)
        end
      end

      # Some trickery to lazy load this to fire a deprecation warning if an app references it
      CONDITION_KEYS ||= LazyObject.new do
        Origen.log.deprecate 'ATP::AST::Builder::CONDITION_KEYS is frozen and is no longer maintained, consider switching to ATP::Flow::CONDITION_KEYS.keys for similar functionality'
        [:if_enabled, :enabled, :enable_flag, :enable, :if_enable, :unless_enabled, :not_enabled,
         :disabled, :disable, :unless_enable, :if_failed, :unless_passed, :failed, :if_passed,
         :unless_failed, :passed, :if_ran, :if_executed, :unless_ran, :unless_executed, :job,
         :jobs, :if_job, :if_jobs, :unless_job, :unless_jobs, :if_any_failed, :unless_all_passed,
         :if_all_failed, :unless_any_passed, :if_any_passed, :unless_all_failed, :if_all_passed,
         :unless_any_failed, :if_flag, :unless_flag, :whenever, :whenever_all, :whenever_any]
      end
    end
  end

  # Processors actually modify the AST to clean and optimize the user input
  # and to implement the flow control API
  module Processors
    autoload :Condition,    'origen_testers/atp/processors/condition'
    autoload :Relationship, 'origen_testers/atp/processors/relationship'
    autoload :PreCleaner, 'origen_testers/atp/processors/pre_cleaner'
    autoload :Marshal, 'origen_testers/atp/processors/marshal'
    autoload :AddIDs, 'origen_testers/atp/processors/add_ids'
    autoload :AddSetResult, 'origen_testers/atp/processors/add_set_result'
    autoload :FlowID, 'origen_testers/atp/processors/flow_id'
    autoload :EmptyBranchRemover, 'origen_testers/atp/processors/empty_branch_remover'
    autoload :AppendTo, 'origen_testers/atp/processors/append_to'
    autoload :Flattener, 'origen_testers/atp/processors/flattener'
    autoload :RedundantConditionRemover, 'origen_testers/atp/processors/redundant_condition_remover'
    autoload :ElseRemover, 'origen_testers/atp/processors/else_remover'
    autoload :OnPassFailRemover, 'origen_testers/atp/processors/on_pass_fail_remover'
    autoload :ApplyPostGroupActions, 'origen_testers/atp/processors/apply_post_group_actions'
    autoload :OneFlagPerTest, 'origen_testers/atp/processors/one_flag_per_test'
    autoload :FlagOptimizer, 'origen_testers/atp/processors/flag_optimizer'
    autoload :AdjacentIfCombiner, 'origen_testers/atp/processors/adjacent_if_combiner'
    autoload :ContinueImplementer, 'origen_testers/atp/processors/continue_implementer'
    autoload :ExtractSetFlags, 'origen_testers/atp/processors/extract_set_flags'
    autoload :SubFlowRemover, 'origen_testers/atp/processors/sub_flow_remover'
  end

  # Summarizers extract summary data from the given AST
  module Summarizers
  end

  # Validators are run on the processed AST to check it for common errors or
  # logical issues that will prevent it being rendered to a test program format
  module Validators
    autoload :DuplicateIDs, 'origen_testers/atp/validators/duplicate_ids'
    autoload :MissingIDs, 'origen_testers/atp/validators/missing_ids'
    autoload :Condition, 'origen_testers/atp/validators/condition'
    autoload :Jobs, 'origen_testers/atp/validators/jobs'
    autoload :Flags, 'origen_testers/atp/validators/flags'
  end

  # Formatters are run on the processed AST to display the flow or to render
  # it to a different format
  module Formatters
    autoload :Basic,   'origen_testers/atp/formatters/basic'
    autoload :Datalog, 'origen_testers/atp/formatters/datalog'
  end

  # Maintains a unique ID counter to ensure that all nodes get a unique ID
  def self.next_id
    @next_id ||= 0
    @next_id += 1
  end
end
