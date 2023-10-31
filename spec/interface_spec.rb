require 'spec_helper'

describe "An interface" do

  class MyDUT
    include Origen::TopLevel
  end

  class MyInterface
    include OrigenTesters::ProgramGenerators
    include Origen::Callbacks

    def initialize(options = {})
      self.resources_filename = "abc"
      add_my_tml if tester.v93k? && tester.smt8?
    end

    def on_my_callback
      $_test_var += 1
    end

    def add_my_tml
      add_tml :my_hash_tml,
        class_name:      'MyTmlHashNamespace',

        # Here is a test definition.
        # The identifier should be lower-cased and underscored, in-keeping with Ruby naming conventions.
        # By default the class name will be the camel-cased version of this identifier, so 'myTest' in
        # this case.
        my_hash_test: {
          # [OPTIONAL] The C++ test method class name can be overridden from the default like this:
          class_name:   'MyHashExampleClass',
          # [OPTIONAL] If the test method does not require a definition in the testmethodlimits section
          #    of the .tf file, you can suppress like this:
          render_limits_in_file: false,
          # Parameters can be defined with an underscored symbol as the name, this can be used
          # if the C++ implementation follows the standard V93K convention of calling the attribute
          # the camel cased version, starting with a lower-cased letter, i.e. 'testerState' in this
          # first example.
          # The attribute definition has two required parameters, the type and the default value.
          # The type can be :string, :current, :voltage, :time, :frequency, integer, :double or :boolean
          pin_list: [:string, ''],
          samples: [:integer, 1],
          precharge_voltage: [:voltage, 0],
          settling_time: [:time, 0],
          # An optional parameter that sets the limits name in the 'testmethodlimits' section
          # of the generated .tf file.  Defaults to 'Functional' if not provided.
          test_name: [:string, 'HashExample'],
          # An optional 3rd parameter can be supplied to provide an array of allowed values. If supplied,
          # Origen will raise an error upon an attempt to set it to an unlisted value.
          tester_state: [:string, 'CONNECTED', %w(CONNECTED UNCHANGED DISCONNECTED)],
          force_mode: [:string, 'VOLT', %w(VOLT CURR)],
          # The name of another parameter can be supplied as the type argument, meaning that the type
          # here will be either :current or :voltage depending on the value of :force_mode
          force_value: [:force_mode, 3800.mV],
          # In cases where the C++ library has deviated from standard attribute naming conventions
          # (camel-cased with lower cased first character), the absolute attribute name can be given
          # as a string.
          # The Origen accessor for these will be the underscored version, with '.' characters
          # converted to underscores e.g. tm.an_unusual_name
          'hashParameter':  [{param_name0: [:string, 'NO'], param_name1: [:integer, 0]}],
          # Define any methods you want the test method to have
          methods: {
            # If you define a method called 'finalize', it will be called automatically before the test
            # method is finally rendered, making it a good place to do any last minute attribute
            # manipulation based on the final values that have been set by the user.
            # The test method object itself will be passed in as an argument.
            #
            # In this example it will set the pre-charge if it has not already been set and a voltage is
            # being forced above a given threshold.
            finalize: -> (tm) {
              if tm.force_mode == 'VOLT' && tm.precharge_voltage == 0 && tm.force_value > 3.5.V
                # Set the pre-charge level to 1V below the force value
                tm.precharge_voltage = tm.force_value - 1.V
              end
            },
            # Example of a custom helper method, here to provide a single method to force a current and
            # which will configure multiple test method attributes.
            force_current: -> (tm, value) {
              tm.force_mode = 'CURR'
              tm.force_value = value
            },
          }
        } 
    end
  end

  before :each do
    # Ugly hack, should add a proper API for this, though it should only
    # ever be needed in a test situation
    Origen.instance_variable_set("@interface", nil)
    Origen.file_handler.current_file = Pathname.new("#{Origen.root}/spec/interface_spec")
  end

  after :all do
    # Ugly hack, should add a proper API for this, though it should only
    # ever be needed in a test situation
    Origen.instance_variable_set("@interface", nil)
  end

  it "resources_filename can be set from an interface initialize" do
    Origen.environment.temporary = "uflex.rb"
    Origen.load_target("dut.rb")
    Flow.create interface: "MyInterface" do
      Origen.interface.test_instances_filename.should == "abc"
    end
  end

  it "interface methods can be accessed outside of a flow" do
    Origen.file_handler.current_file = nil
    Origen.reset_interface
  end

  it "interfaces can include callbacks" do
    Origen.app.unload_target!
    Origen.target.temporary = -> do
      MyDUT.new
      OrigenTesters::V93K.new
    end
    Origen.target.load!

    Flow.create interface: "MyInterface" do
      $_test_var = 0
      Origen.listeners_for(:on_my_callback).each { |l| l.on_my_callback } 
      $_test_var.should == 1
      # Test that the interface remains registered during a sub-flow
      Flow.create do
        # Verify that the listening object is the current interface instance
        Origen.interface.object_id.should == Origen.app.instantiated_callback_listeners.first.object_id
        Origen.listeners_for(:on_my_callback).each { |l| l.on_my_callback } 
        $_test_var.should == 2
      end
    end

    # Run again, this is to make sure the previous interface is de-registered
    # properly and it does not hang around to increment this variable twice
    Flow.create interface: "MyInterface" do
      $_test_var = 0
      Origen.listeners_for(:on_my_callback).each { |l| l.on_my_callback } 
      $_test_var.should == 1
    end
  end
end

describe "An interface that does not want the target re-loaded" do

  class InterfaceThatLikesSpeed
    include OrigenTesters::ProgramGenerators

    attr_accessor :reload_target

    def initialize(options = {})
      @reload_target = false
    end
  end

  before :each do
    # Ugly hack, should add a proper API for this, though it should only
    # ever be needed in a test situation
    Origen.instance_variable_set("@interface", nil)
    Origen.file_handler.current_file = Pathname.new("#{Origen.root}/spec/interface_spec")
  end

  after :all do
    # Ugly hack, should add a proper API for this, though it should only
    # ever be needed in a test situation
    Origen.instance_variable_set("@interface", nil)
    Origen.target.temporary = nil
    Origen.app.unload_target!
  end

  it "Target is only loaded once during flow generation" do
    Origen.environment.temporary = "uflex.rb"
    Origen.load_target("dut.rb")
    dut.target_load_count.should == 1
    Flow.create interface: 'InterfaceThatLikesSpeed' do
      dut.target_load_count.should == 1
    end
    dut.target_load_count.should == 1
    # The interface wins the day over any flow file settings
    Flow.create interface: 'InterfaceThatLikesSpeed', reload_target: true do
      dut.target_load_count.should == 1
    end
    dut.target_load_count.should == 1
  end
end

