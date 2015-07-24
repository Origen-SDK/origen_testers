require 'origen_testers/test/j750_base_interface'
module OrigenTesters
  module Test
    class J750Interface < J750BaseInterface
      include OrigenTesters::J750::Generator
    end
  end
end
