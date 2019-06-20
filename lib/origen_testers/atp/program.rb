module OrigenTesters::ATP
  # Program is the top-level container for a collection of test flows
  class Program
    # Load a program from a previously saved file
    def self.load(file)
      p = nil
      File.open(file) do |f|
        p = Marshal.load(f)
      end
      p
    end

    def flow(name, options = {})
      flows[name] ||= Flow.new(self, name, options)
    end

    def flows
      @flows ||= {}.with_indifferent_access
      # To rescue previously created programs which have been loaded
      unless @flows.is_a?(ActiveSupport::HashWithIndifferentAccess)
        @flows = @flows.with_indifferent_access
      end
      @flows
    end

    # Save the program to a file
    def save(file)
      File.open(file, 'w') do |f|
        Marshal.dump(self, f)
      end
    end

    def respond_to?(*args)
      flows.key?(args.first) || super
    end

    def method_missing(method, *args, &block) # :nodoc:
      if f = flows[method]
        define_singleton_method method do
          f
        end
        f
      else
        super
      end
    end
  end
end
