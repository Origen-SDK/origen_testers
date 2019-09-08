module OrigenTesters
  module Decompiler
    module RSpec
      module Common
        def approved_pat(name_or_sym)
          if name_or_sym.is_a?(Symbol)
            if patterns.key?(name_or_sym)
              approved_dir.join("#{patterns[name_or_sym]}#{ext}")
            elsif name_or_sym == :delay || name_or_sym == :simple
              approved_dir.join("#{name_or_sym}#{ext}")
            else
              fail "Could not look up pattern for :#{name_or_sym}"
            end
          else
            approved_dir.join("#{name_or_sym}#{ext}")
          end
        end
        
        def execution_result(name_or_sym)
          execution_results_dir.join(pattern(name_or_sym))
        end

        def execution_results_dir
          approved_dir.join('decompiler/executions')
        end
        
        def pattern_model(pat)
          pattern_models_dir.join("#{pattern(pat)}.yaml")
        end
        
        def pattern_models_dir
          approved_dir.join('decompiler/models')
        end
        
        def method_missing(m, *args, &block)
          if @defs.key?(m)
            define_singleton_method(m) { @defs[m] }
            return @defs[m]
          end
          super
        end
        
        def [](k)
          @defs[k]
        end
        
        def workout
          @defs[:patterns][:workout]
        end
        
        def execution_output
          "#{Origen.app.root}/output/#{@defs[:approved_dir].to_s.split('/').last}/decompile#{ext}"
        end

        def context_str(vector_type:, platform: nil, index: nil, index_key: nil)
          base = platform.nil? ? "validating standard node :#{vector_type} " : "validating platform-specific (#{platform}) vector type #{vector_type} "
          if index_key
            base + "for vector :#{index_key}"
          else
            base + "at index #{index || fail('No :index or :index_key options given!')}"
          end
        end

        def pattern(name_or_sym)
          if name_or_sym.is_a?(Symbol)
            if patterns.key?(name_or_sym)
              "#{patterns[name_or_sym]}#{ext}"
            elsif name_or_sym == :delay || name_or_sym == :simple
              "#{name_or_sym}#{ext}"
            else
              fail "Could not look up pattern for :#{name_or_sym}"
            end
          else
            if name_or_sym.to_s.end_with?(ext)
              name_or_sym
            else
              "#{name_or_sym}#{ext}"
            end
          end
        end
        
        def defs
          OrigenTesters::Decompiler::RSpec.defs
        end

        def generate_execution_result(src, decompiler: OrigenTesters::Decompiler)
          $DECOMPILER = decompiler
          $DECOMPILE_PATTERN = approved_dir.join(pattern(src))
          Origen.app.runner.generate(patterns: [defs[:execution_pattern]])
          
          # Return the expected location of the pattern output
          execution_output
        end
        
        def corner_case_dir
          approved_dir.join('decompiler/corner_cases')
        end

        def corner_case(name)
          corner_case_dir.join("#{name}#{ext}")
        end
        
        def error_condition_dir
          approved_dir.join('decompiler/error_conditions')
        end

        def error_condition(name)
          error_condition_dir.join("#{name}#{ext}")
        end

        def decompile(pattern)
          decompiler.new(pattern).decompile
        end

        def current=(current_pattern)
          @current_pattern = current_pattern
        end
        
        def current
          @current_pattern
        end
      end

    end
  end
end

