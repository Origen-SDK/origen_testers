require 'origen_testers/test/j750_base_interface'
module OrigenTesters
  module Test
    class J750HPTInterface < J750BaseInterface
      include OrigenTesters::J750_HPT::Generator
    end
  end
end
