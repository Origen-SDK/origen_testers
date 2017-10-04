require 'spec_helper'

describe 'OrigenTesters SiteConfig' do

  it 'Gets the origen_testers site configs properly' do
    OrigenTesters.site_config.v93k_windows_pattern_compiler.should == nil

    OrigenTesters.site_config.j750_linux_pattern_compiler.should == "/company/path/to/j750/linux/pattern/compiler"
  end

  it 'Properly fails if site config not found and must-be-present (!) is used' do
    lambda { OrigenTesters.site_config.v93k_windows_pattern_compiler! }.should raise_error
  end
end
