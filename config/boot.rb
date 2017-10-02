require "origen_testers"

# This file is only loaded when the testers is running standalone,
# therefore anything required here will be loaded for development only
require "origen_testers/test/dut.rb"
require "origen_testers/test/block.rb"
require "origen_testers/test/dut2.rb"
require "origen_testers/test/dut3.rb"
require "origen_testers/test/dut4.rb"
require "origen_testers/test/nvm.rb"

require "origen_testers/test/interface"
require "origen_testers/test/basic_interface"
require "origen_testers/test/custom_test_interface"
