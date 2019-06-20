# This builds an example test program that can be used within
# tests or used to experiment in the console
# Within the console this program is available as 'program'
def _example_program
  p = OrigenTesters::ATP::Program.new
  f = p.flow(:sort1)
  f.test "test1", bin: 3, sbin: 100 
  f.test "test2", bin: 3, sbin: 110 
  f.test "test3", bin: 3, sbin: 120 

  p
end
