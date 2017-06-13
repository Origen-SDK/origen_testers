# Pattern generator tests

# Legacy tests
ARGV = %w(j750.list -t legacy -e j750.rb -r approved/j750)
load "#{Origen.top}/lib/origen/commands/generate.rb"

ARGV = %w(v93k_workout -t legacy -e v93k -r approved/v93k)
load "#{Origen.top}/lib/origen/commands/generate.rb"

# Common tests
ARGV = %w(regression.list -t dut.rb -e j750.rb -r approved/j750)
load "#{Origen.top}/lib/origen/commands/generate.rb"

ARGV = %w(regression.list -t dut.rb -e j750_hpt.rb -r approved/j750_hpt)
load "#{Origen.top}/lib/origen/commands/generate.rb"

ARGV = %w(regression.list -t dut.rb -e uflex -r approved/ultraflex)
load "#{Origen.top}/lib/origen/commands/generate.rb"

ARGV = %w(regression.list -t dut.rb -e v93k -r approved/v93k)
load "#{Origen.top}/lib/origen/commands/generate.rb"

ARGV = %w(tester_overlay tester_store -t dut3.rb -e uflex -r approved/generic_overlay_capture/ultraflex)
load "#{Origen.top}/lib/origen/commands/generate.rb"

ARGV = %w(tester_overlay tester_store -t dut3.rb -e j750.rb -r approved/generic_overlay_capture/j750)
load "#{Origen.top}/lib/origen/commands/generate.rb"
