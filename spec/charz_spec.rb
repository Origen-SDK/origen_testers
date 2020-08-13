require 'spec_helper'

describe 'Charz' do

  class MyInterface
    include OrigenTesters::ProgramGenerators
    include OrigenTesters::Charz

    def initialize(options = {})
    end

  end

  before :all do
    Origen.environment.temporary = "uflex"
    Origen.load_target("dut.rb")
    Origen.file_handler.current_file = Pathname.new("#{Origen.root}/spec/charz_spec")
  end

  after :all do
    Origen.instance_variable_set("@interface", nil)
  end

  describe 'Accessors' do
    describe "#charz_stack" do
      before :each do
        Origen.instance_variable_set("@interface", nil)
      end

      it "initializes to Array" do
        Flow.create interface: "MyInterface" do
          charz_stack.should == []
        end
      end

      it "doesn't overwrite custom types" do
        Flow.create interface: "MyInterface" do
          charz_stack = :custom
          charz_stack.should == :custom
        end
      end
    end

    describe "#charz_profiles" do
      before :each do
        Origen.instance_variable_set("@interface", nil)
      end

      it "initializes to Hash" do
        Flow.create interface: "MyInterface" do
          charz_profiles.should == {}
        end
      end

      it "doesn't overwrite custom types" do
        Flow.create interface: "MyInterface" do
          charz_profiles = :custom
          charz_profiles.should == :custom
        end
      end
    end

    describe "#charz_routines" do
      before :each do
        Origen.instance_variable_set("@interface", nil)
      end

      it "initializes to Hash" do
        Flow.create interface: "MyInterface" do
          charz_routines.should == {}
        end
      end

      it "doesn't overwrite custom types" do
        Flow.create interface: "MyInterface" do
          charz_routines = :custom
          charz_routines.should == :custom
        end
      end
    end

    describe "#charz_session" do
      before :each do
        Origen.instance_variable_set("@interface", nil)
      end

      it "initializes to Session" do
        Flow.create interface: "MyInterface" do
          charz_session.class.should == OrigenTesters::Charz::Session
        end
      end

      it "doesn't overwrite custom types" do
        Flow.create interface: "MyInterface" do
          charz_session = :custom
          charz_session.should == :custom
        end
      end
    end

    describe "#eof_charz_tests" do
      before :each do
        Origen.instance_variable_set("@interface", nil)
      end

      it "initializes to Array" do
        Flow.create interface: "MyInterface" do
          eof_charz_tests.should == []
        end
      end

      it "doesn't overwrite custom types" do
        Flow.create interface: "MyInterface" do
          eof_charz_tests = :custom
          eof_charz_tests.should == :custom
        end
      end
    end
  end

  describe "#add_charz_routine" do
    before :each do
      Origen.instance_variable_set("@interface", nil)
    end

    it 'initialized a default routine' do
      Flow.create interface: 'MyInterface' do
        add_charz_routine :routine do |routine|
          routine.start = 1.0.V
          routine.stop  = 0.5.V
          routine.res   = 5.mV
          routine.spec  = 'vdd'
        end
        charz_routines[:routine].spec.should == 'vdd'
        charz_routines[:routine].class.should == OrigenTesters::Charz::Routine
      end
    end

    it 'initialized a search routine' do
      Flow.create interface: 'MyInterface' do
        add_charz_routine :search_routine, type: :search do |routine|
          routine.start = 1.0.V
          routine.stop  = 0.5.V
          routine.res   = 5.mV
          routine.spec  = 'vdd'
        end
        charz_routines[:search_routine].start.should == 1.0.V
        charz_routines[:search_routine].class.should == OrigenTesters::Charz::SearchRoutine
      end
    end

    it 'initialized a shmoo routine' do
      Flow.create interface: 'MyInterface' do
        add_charz_routine :shmoo_routine, type: :shmoo do |routine|
          routine.x_start = 2.0.V
          routine.x_stop  = 1.5.V
          routine.x_res   = 10.mV
          routine.x_spec  = 'vdd1'
          routine.y_start = 3.0.V
          routine.y_stop  = 2.5.V
          routine.y_res   = 15.mV
          routine.y_spec  = 'vdd2'
        end
        charz_routines[:shmoo_routine].x_spec.should == 'vdd1'
        charz_routines[:shmoo_routine].y_spec.should == 'vdd2'
        charz_routines[:shmoo_routine].class.should == OrigenTesters::Charz::ShmooRoutine
      end
    end

    it 'errors when adding a routine with an existing id' do
      Flow.create interface: 'MyInterface' do
          add_charz_routine :routine do |routine|
            routine.start = 1.0.V
            routine.stop  = 0.5.V
            routine.res   = 5.mV
            routine.spec  = 'vdd'
          end
      end
      expect {
        Origen.interface.add_charz_routine :routine do |routine|
          routine.start = 1.0.V
          routine.stop  = 0.5.V
          routine.res   = 5.mV
          routine.spec  = 'vdd'
        end
      }.to raise_error
    end
  end

  describe "#add_charz_profile" do

    class MyCharzInterface
      include OrigenTesters::ProgramGenerators
      include OrigenTesters::Charz

      def initialize(options = {})
        add_charz_routine :routine1 do |routine|
          routine.start = 1.0.V
          routine.stop  = 0.5.V
          routine.res   = 5.mV
          routine.spec  = 'vdd1'
        end
        add_charz_routine :routine2 do |routine|
          routine.start = 1.0.V
          routine.stop  = 0.5.V
          routine.res   = 5.mV
          routine.spec  = 'vdd2'
        end
      end

    end

    before :each do
      Origen.instance_variable_set("@interface", nil)
    end

    it 'creates a profile' do
      Flow.create interface: 'MyCharzInterface' do
        add_charz_profile :my_profile do |profile|
          profile.routines = [:routine1, :routine2]
        end
        charz_profiles[:my_profile].routines.should == [:routine1, :routine2]
        charz_profiles[:my_profile].placement.should == :inline # defaults to inline
      end
    end


    it 'creates a profile again' do
      expect {
        Flow.create interface: 'MyCharzInterface' do
          add_charz_profile :my_profile do |profile|
            profile.routines = [:routine1, :routine2]
          end
          add_charz_profile :my_profile do |profile|
            profile.routines = [:routine1, :routine2]
          end
        end
      }.to raise_error
      Origen.reset_interface
    end

    it 'errors when unknown routines are passed' do
      expect {
        Flow.create interface: 'MyCharzInterface' do
          add_charz_profile :my_profile do |profile|
            profile.routines = [:routineABC, :routine123]
          end
        end
      }.to raise_error
    end

  end

end
