# Simple script to run in place of real compiler; for spec testing only
class V93K_PatCompiler
  def compile
    puts 'V93000 Pattern Compiler - fake version' 
  end
end

if __FILE__ == $0
  aif = V93K_PatCompiler.new
  aif.compile
end
