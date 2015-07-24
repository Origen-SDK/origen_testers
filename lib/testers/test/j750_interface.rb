require 'testers/test/j750_base_interface'
module Testers
  module Test
    class J750Interface < J750BaseInterface
      include Testers::J750::Generator
    end
  end
end
