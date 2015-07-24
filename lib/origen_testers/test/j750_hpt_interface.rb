require 'testers/test/j750_base_interface'
module Testers
  module Test
    class J750HPTInterface < J750BaseInterface
      include Testers::J750_HPT::Generator
    end
  end
end
