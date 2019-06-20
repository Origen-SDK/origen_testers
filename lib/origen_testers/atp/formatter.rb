module OrigenTesters::ATP
  class Formatter < Processor
    def format(node, options = {})
      process(node)
    end

    def run_and_format(node, options = {})
      ast = Runner.new.run(node, options)
      format(ast, options)
    end

    def self.format(node, options = {})
      new.format(node, options)
    end

    def self.run_and_format(node, options = {})
      ast = Runner.new.run(node, options)
      format(ast, options)
    end

    def self.run(*args)
      run_and_format(*args)
    end
  end
end
