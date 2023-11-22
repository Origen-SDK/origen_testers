require 'spec_helper'

describe 'Charz' do

  class MyInterface
    include OrigenTesters::ProgramGenerators
    include OrigenTesters::Charz

    def initialize(options = {})
    end

  end

  class MyCharzRoutineInterface
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
      add_charz_profile :my_profile do |profile|
        profile.name = 'my_charz_profile'
        profile.routines = [:routine1, :routine2]
        profile.on_result = :fail
        profile.placement = :eof
      end
    end

  end

  before :all do
    Origen.environment.temporary = "uflex.rb"
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

      it "allows custom defaults" do
        Flow.create interface: "MyInterface" do
          charz_session = OrigenTesters::Charz::Session.new(defaults: {
            placement: :eof,
            on_result: :fail,
            enables: nil,
            and_enables: nil,
            flags: nil,
            and_flags: nil,
            name: 'custom_charz',
            charz_only: false
          })
          charz_session.defaults[:placement].should == :eof
          charz_session.defaults[:on_result].should == :fail
          charz_session.defaults[:enables].should == nil
          charz_session.defaults[:and_enables].should == nil
          charz_session.defaults[:flags].should == nil
          charz_session.defaults[:and_flags].should == nil
          charz_session.defaults[:name].should == 'custom_charz'
          charz_session.defaults[:charz_only].should == false
        end
      end

      it "tracks the current instance" do
        Flow.create interface: 'MyInterface' do
          add_charz_routine :search_routine, type: :search do |routine|
            routine.start = 1.0.V
            routine.stop  = 0.5.V
            routine.res   = 5.mV
            routine.spec  = 'vdd'
          end
          Origen.interface.add_charz_profile :my_profile do |profile|
            profile.routines = [:search_routine]
          end
          Origen.interface.charz_instance.should == nil
          charz_on :my_profile
          Origen.interface.charz_instance.id.should == :my_profile
          Origen.interface.charz_session.loop_instances do
            Origen.interface.charz_instance.id.should == :my_profile
          end
          Origen.interface.charz_instance.id.should == :my_profile
          charz_off
          Origen.interface.charz_instance.should == nil
          Origen.interface.charz_session.current_instance = :dummy
          Origen.interface.charz_instance.should == :dummy
        end
      end

      it "enables charz_only if any instance is set, unless on_result" do
        Flow.create interface: 'MyInterface' do
          add_charz_routine :search_routine, type: :search do |routine|
            routine.start = 1.0.V
            routine.stop  = 0.5.V
            routine.res   = 5.mV
            routine.spec  = 'vdd'
          end
          Origen.interface.add_charz_profile :my_profile do |profile|
            profile.routines = [:search_routine]
          end
          Origen.interface.add_charz_profile :my_profile_cz_only do |profile|
            profile.charz_only = true
            profile.routines = [:search_routine]
          end
          Origen.interface.add_charz_profile :my_profile_on_result do |profile|
            profile.on_result = :pass
            profile.routines = [:search_routine]
          end
          Origen.interface.add_charz_profile :my_profile_keep_parent do |profile|
            profile.force_keep_parent = true
            profile.routines = [:search_routine]
          end
          charz_on :my_profile
          Origen.interface.charz_only?.should == false
          charz_on_append :my_profile_cz_only
          Origen.interface.charz_only?.should == true
          charz_on_append :my_profile_on_result
          Origen.interface.charz_only?.should == false
          charz_off_truncate
          Origen.interface.charz_only?.should == true
          charz_on_append :my_profile_keep_parent
          Origen.interface.charz_only?.should == false
          charz_off
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
        charz_routines[:search_routine].type.should == :search
        charz_routines[:search_routine].class.should == OrigenTesters::Charz::SearchRoutine
      end
    end

    it 'errors for missing search routine attributes' do
      Flow.create interface: 'MyInterface' do
      end
      expect {
        Origen.interface.add_charz_routine :search_routine, type: :search do |routine|
          routine.start = 1.0.V
          routine.stop  = 0.5.V
          routine.res   = 5.mV
        end
      }.to raise_error
    end

    it 'errors for invalid search routine resolution' do
      Flow.create interface: 'MyInterface' do
      end
      expect {
        Origen.interface.add_charz_routine :search_routine, type: :search do |routine|
          routine.start = 1.0.V
          routine.stop  = 0.5.V
          routine.res   = 5.V
          routine.spec  = 'vdd'
        end
      }.to raise_error
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

    it 'errors for missing shmoo routine attributes' do
      Flow.create interface: 'MyInterface' do
      end
      expect {
        Origen.interface.add_charz_routine :shmoo_routine, type: :shmoo do |routine|
          routine.x_start = 2.0.V
          routine.x_stop  = 1.5.V
          routine.x_res   = 10.mV
          routine.y_start = 3.0.V
          routine.y_stop  = 2.5.V
          routine.y_res   = 15.mV
          routine.y_spec  = 'vdd2'
        end
      }.to raise_error
    end

    it 'errors for matching shmoo routine specs' do
      Flow.create interface: 'MyInterface' do
      end
      expect {
        Origen.interface.add_charz_routine :shmoo_routine, type: :shmoo do |routine|
          routine.x_start = 2.0.V
          routine.x_stop  = 1.5.V
          routine.x_res   = 10.mV
          routine.x_spec  = 'vdd2'
          routine.y_start = 3.0.V
          routine.y_stop  = 2.5.V
          routine.y_res   = 15.mV
          routine.y_spec  = 'vdd2'
        end
      }.to raise_error
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

    before :each do
      Origen.instance_variable_set("@interface", nil)
    end

    it 'creates a profile' do
      Flow.create interface: 'MyCharzRoutineInterface' do
        add_charz_profile :my_profile do |profile|
          profile.routines = [:routine1, :routine2]
        end
        charz_profiles[:my_profile].routines.should == [:routine1, :routine2]
        charz_profiles[:my_profile].placement.should == :inline # defaults to inline
      end
    end

    it 'errors on duplicate profile ids' do
      Flow.create interface: 'MyCharzRoutineInterface' do
        add_charz_profile :my_profile do |profile|
          profile.routines = [:routine1]
        end
      end
      expect {
        Origen.interface.add_charz_profile :my_profile do |profile|
          profile.routines = [:routine2]
        end
      }.to raise_error
    end

    it 'errors when profile routines are not an array' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      expect {
        Origen.interface.add_charz_profile :my_profile do |profile|
        end
      }.to raise_error
    end

    it 'errors when no routines are passed' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      expect {
        Origen.interface.add_charz_profile :my_profile do |profile|
          profile.routines = []
        end
      }.to raise_error
    end

    it 'passes when no routines are passed but @allow_empty_routines is asserted' do
      Flow.create interface: 'MyCharzRoutineInterface' do
        add_charz_profile :my_profile do |profile|
          profile.routines = []
          profile.allow_empty_routines = true
        end
        charz_profiles[:my_profile].routines.should == []
      end
    end

    it 'errors when unknown routines are passed' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      expect {
        Origen.interface.add_charz_profile :my_profile do |profile|
          profile.routines = [:routineABC, :routine123]
        end
      }.to raise_error
    end

    it 'errors when invalid placements are passed' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      expect {
        Origen.interface.add_charz_profile :my_profile do |profile|
          profile.routines = [:routine1]
          profile.placement = :unknown
        end
      }.to raise_error
    end

    it 'allows custom placements' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      Origen.interface.add_charz_profile :my_profile do |profile|
        profile.routines = [:routine1]
        profile.placement = :unknown
        profile.valid_placements = [:inline, :eof, :unknown]
      end
    end

    it 'errors when invalid on_results are passed' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      expect {
        Origen.interface.add_charz_profile :my_profile do |profile|
          profile.routines = [:routine1]
          profile.on_result = :unknown
        end
      }.to raise_error
    end

    it 'allows custom on_results' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      Origen.interface.add_charz_profile :my_profile do |profile|
        profile.routines = [:routine1]
        profile.on_result = :unknown
        profile.valid_on_results = [:pass, :fail, :unknown]
      end
    end

    it 'errors when on_result and charz_only are set' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      expect {
        Origen.interface.add_charz_profile :my_profile do |profile|
          profile.routines = [:routine1]
          profile.on_result = :fail
          profile.charz_only = true
        end
      }.to raise_error
    end
    
    it 'errors when and_enables and and_flags are set' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      expect {
        Origen.interface.add_charz_profile :my_profile do |profile|
          profile.routines =[:routine1]
          profile.and_enables = true
          profile.and_flags = true
        end
      }.to raise_error
    end

    it 'allows gates to be an array' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      Origen.interface.add_charz_profile :my_profile do |profile|
        profile.routines = [:routine1, :routine2]
        profile.enables = [:my_enable]
        profile.flags = ['$my_flag']
      end
    end

    it 'allows anded gates to be an array' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      Origen.interface.add_charz_profile :my_profile do |profile|
        profile.routines = [:routine1, :routine2]
        profile.enables = [:my_enable1, :my_enable2]
        profile.and_enables = true
        profile.flags = ['$my_flag']
      end
    end
    
    it 'errors when gate array contains invalid types' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      expect {
      Origen.interface.add_charz_profile :my_profile do |profile|
        profile.routines = [:routine1, :routine2]
        profile.enables = [1]
      end
      }.to raise_error
    end

    it 'errors when anded gate array contains invalid types' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      expect {
      Origen.interface.add_charz_profile :my_profile do |profile|
        profile.routines = [:routine1, :routine2]
        profile.enables = [:valid_type, 1]
        profile.and_enables = true
      end
      }.to raise_error
    end
    
    it 'allows gates to be a hash' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      Origen.interface.add_charz_profile :my_profile do |profile|
        profile.routines = [:routine1, :routine2]
        profile.enables = { my_enable: :routine1 }
        profile.flags = { my_flag: :routine2 }
      end
    end

    it 'allows anded gates to be a hash' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      Origen.interface.add_charz_profile :my_profile do |profile|
        profile.routines = [:routine1, :routine2]
        profile.enables = { routine1: [:my_enable1, :my_enable2], routine2: :my_enable2 }
        profile.and_enables = true
        profile.flags = [:my_flag]
      end
    end

    it 'errors when gates are a nested hash' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      expect {
      Origen.interface.add_charz_profile :my_profile do |profile|
        profile.routines = [:routine1, :routine2]
        profile.enables = { { my_flag: :routine1 } => :routine2  }
      end
      }.to raise_error
    end

    it 'errors when anded gates are a nested hash' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      expect {
      Origen.interface.add_charz_profile :my_profile do |profile|
        profile.routines = [:routine1, :routine2]
        profile.enables = { { my_flag: :routine1 } => :routine2  }
        profile.and_enables = true
      end
      }.to raise_error
    end

    it 'errors when gate hash refers to unknown routine' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      expect {
      Origen.interface.add_charz_profile :my_profile do |profile|
        profile.routines = [:routine1, :routine2]
        profile.enables = { my_enable: :routine3 }
      end
      }.to raise_error
    end

    it 'errors when anded gate hash refers to unknown routine' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      expect {
      Origen.interface.add_charz_profile :my_profile do |profile|
        profile.routines = [:routine1, :routine2]
        profile.enables= { routine3: :my_enable }
        profile.and_enables = true
      end
      }.to raise_error
    end

    it 'allows custom attributes' do
      Flow.create interface: 'MyCharzRoutineInterface' do
      end
      Origen.interface.add_charz_profile :my_profile do |profile|
        profile.routines = [:routine1, :routine2]
        profile.custom_setting = :custom
      end
      Origen.interface.charz_profiles[:my_profile].custom_setting.should == :custom
    end
  end

  describe '#charz_on' do

    before :each do
      Origen.instance_variable_set("@interface", nil)
    end

    it 'updates the session with a profile' do
      Flow.create interface: 'MyCharzInterface' do
        charz_on :my_profile
        charz_session.active.should == true
        charz_session.valid.should == true
        charz_session.charz_only.should == false
        charz_session.enables.should == nil
        charz_session.and_enables.should == false
        charz_session.flags.should == nil
        charz_session.and_flags.should == false
        charz_session.name.should == 'my_charz_profile'
        charz_session.placement.should == :eof
        charz_session.on_result.should == :fail
        charz_session.routines.should == [:routine1, :routine2]
      end
    end

    it 'updates the session with a profile and optional overrides' do
      Flow.create interface: 'MyCharzInterface' do
        charz_on :my_profile, { placement: :inline, on_result: :pass }
        charz_session.active.should == true
        charz_session.valid.should == true
        charz_session.charz_only.should == false
        charz_session.enables.should == nil
        charz_session.and_enables.should == false
        charz_session.flags.should == nil
        charz_session.and_flags.should == false
        charz_session.name.should == 'my_charz_profile'
        charz_session.placement.should == :inline
        charz_session.on_result.should == :pass
        charz_session.routines.should == [:routine1, :routine2]
      end
    end

    it 'updates the session with a routine' do
      Flow.create interface: 'MyCharzInterface' do
        charz_on :routine1, { type: :routine }
        charz_session.active.should == true
        charz_session.valid.should == true
        charz_session.charz_only.should == false
        charz_session.enables.should == nil
        charz_session.and_enables.should == false
        charz_session.flags.should == nil
        charz_session.and_flags.should == false
        charz_session.name.should == :routine1
        charz_session.placement.should == :inline
        charz_session.on_result.should == nil
        charz_session.routines.should == [:routine1]
      end
    end

    it 'errors when an invalid session is created' do
      Flow.create interface: 'MyCharzInterface' do
      end
      expect {
        Origen.interface.charz_on :my_profile, { enables: 1 }
      }.to raise_error
    end

    it 'errors when an unknown profile is passed' do
      Flow.create interface: 'MyCharzInterface' do
      end
      expect {
        Origen.interface.charz_on :my_new_profile
      }.to raise_error
    end

    it 'updates a previously valid session' do
      Flow.create interface: 'MyCharzInterface' do
        # initial session
        charz_on :my_profile, { placement: :inline, on_result: :pass }
        charz_session.active.should == true
        charz_session.valid.should == true
        charz_session.charz_only.should == false
        charz_session.enables.should == nil
        charz_session.and_enables.should == false
        charz_session.flags.should == nil
        charz_session.and_flags.should == false
        charz_session.name.should == 'my_charz_profile'
        charz_session.placement.should == :inline
        charz_session.on_result.should == :pass
        charz_session.routines.should == [:routine1, :routine2]

        # second session
        charz_on :routine1, { type: :routine }
        charz_session.active.should == true
        charz_session.valid.should == true
        charz_session.charz_only.should == false
        charz_session.enables.should == nil
        charz_session.and_enables.should == false
        charz_session.flags.should == nil
        charz_session.and_flags.should == false
        charz_session.name.should == :routine1
        charz_session.placement.should == :inline
        charz_session.on_result.should == nil
        charz_session.routines.should == [:routine1]
      end
    end

    # Note: Rewrite now makes this case essentially impossible to trigger
    #
    # it 'errors when a priority value cant be set' do
    #   Flow.create interface: 'MyCharzInterface' do
    #   end
    #   Origen.interface.charz_session = OrigenTesters::Charz::Session.new(defaults: {})
    #   expect { Origen.interface.charz_on :my_profile }.to raise_error
    # end

    it 'errors with an unknown type' do
      Flow.create interface: 'MyCharzInterface' do
      end
      expect { Origen.interface.charz_on :my_profile, { type: :unknown } }.to raise_error
    end

    it 'allows array of routines to be called' do
      Flow.create interface: 'MyCharzInterface' do
      end
      Origen.interface.charz_on [:routine1, :routine2], { type: :routine }
      Origen.interface.charz_session.routines.should == [:routine1, :routine2]
    end

  end

  describe '#charz_off' do

    before :each do
      Origen.instance_variable_set("@interface", nil)
    end

    it 'allows calling before a session is created' do
      Flow.create interface: 'MyCharzInterface' do
        charz_session.valid.should == false
        charz_session.active.should == false
        charz_off
        charz_session.valid.should == false
        charz_session.active.should == false
      end
    end

    it 'returns the session to inactive after last stack pop' do
      Flow.create interface: 'MyCharzInterface' do
        charz_on :my_profile
        charz_session.valid.should == true
        charz_session.active.should == true
        charz_off
        charz_session.valid.should == false
        charz_session.active.should == false
      end
    end

    it 'tracks session updates after stack pop' do
      Flow.create interface: 'MyCharzInterface' do
        charz_on :my_profile, { on_result: :pass }
        charz_session.valid.should == true
        charz_session.active.should == true
        charz_session.placement.should == :eof
        charz_session.on_result.should == :pass

        charz_on :routine1, { type: :routine }
        charz_session.active.should == true
        charz_session.valid.should == true
        charz_session.placement.should == :inline
        charz_session.on_result.should == nil

        charz_off
        charz_session.valid.should == true
        charz_session.active.should == true
        charz_session.placement.should == :eof
        charz_session.on_result.should == :pass
      end
    end
  end

  describe '#charz_active?' do

    before :each do
      Origen.instance_variable_set("@interface", nil)
    end

    it 'initializes to inactive' do
      Flow.create interface: 'MyCharzInterface' do
        charz_active?.should == false
      end
    end

    it 'activates after charz_on' do
      Flow.create interface: 'MyCharzInterface' do
        charz_on :my_profile
        charz_active?.should == true
      end
    end

    it 'deactivates after charz_off' do
      Flow.create interface: 'MyCharzInterface' do
        charz_on :my_profile
        charz_active?.should == true
        charz_off
        charz_active?.should == false
      end
    end

  end

  describe '#charz_only?' do

    def charz_only?
      charz_active? && charz_session.charz_only
    end
    before :each do
      Origen.instance_variable_set("@interface", nil)
    end

    it 'initalizes to false' do
      Flow.create interface: 'MyCharzInterface' do
        charz_only?.should == false
      end
    end

    it 'indicates false' do
      Flow.create interface: 'MyCharzInterface' do
        charz_on :my_profile
        charz_only?.should == false
      end
    end

    it 'indicates true' do
      Flow.create interface: 'MyCharzInterface' do
        charz_on :my_profile, { on_result: nil, charz_only: true }
        charz_only?.should == true
      end
    end
  end

  describe '#charz_pause' do

    before :each do
      Origen.instance_variable_set("@interface", nil)
    end
    
    it 'does nothing to an inactive session' do
      Flow.create interface: 'MyCharzInterface' do
        charz_active?.should == false
        charz_pause
        charz_active?.should == false
      end
    end

    it 'pauses an active session' do
      Flow.create interface: 'MyCharzInterface' do
        charz_on :my_profile
        charz_active?.should == true
        charz_pause
        charz_active?.should == false
      end
    end

  end

  describe '#charz_resume' do

    before :each do
      Origen.instance_variable_set("@interface", nil)
    end

    it 'does nothing to an invalid session' do
      Flow.create interface: 'MyCharzInterface' do
        charz_active?.should == false
        charz_session.valid.should == false
        charz_resume
        charz_active?.should == false
        charz_session.valid.should == false
      end
    end

    it 'does nothing to a valid, active session' do
      Flow.create interface: 'MyCharzInterface' do
        charz_on :my_profile
        charz_active?.should == true
        charz_session.valid.should == true
        charz_session.name.should == 'my_charz_profile'
        charz_resume
        charz_active?.should == true
        charz_session.valid.should == true
        charz_session.name.should == 'my_charz_profile'
      end
    end

    it 'resumes a valid, inactive session' do
      Flow.create interface: 'MyCharzInterface' do
        charz_on :my_profile
        charz_pause
        charz_active?.should == false
        charz_session.valid.should == true
        charz_session.name.should == 'my_charz_profile'
        charz_resume
        charz_active?.should == true
        charz_session.valid.should == true
        charz_session.name.should == 'my_charz_profile'
      end
    end

  end

  describe '#set_conditional_charz_id' do

    class MyTest
      attr_accessor :name
      def initialize(name)
        @name = name
      end
    end

    before :each do
      Origen.instance_variable_set("@interface", nil)
    end
    
    it 'restricts the number of arguments' do
      Flow.create interface: 'MyCharzInterface' do
      end
      expect { Origen.interface.set_conditional_charz_id(1, 2, 3) }.to raise_error
    end

    it 'generates an ID' do
      Flow.create interface: 'MyCharzInterface' do
        my_test = MyTest.new('my_test')
        charz_on :my_profile
        # two params
        options = { id: :dummy_id }
        set_conditional_charz_id(my_test, options)
        options[:id].should == :dummy_id
        # one param
        options[:parent_test_name] = :my_test
        set_conditional_charz_id(options)
        options[:id].should == :dummy_id
      end
    end

    it 'does nothing if charz is inactive' do
      Flow.create interface: 'MyCharzInterface' do
        my_test = MyTest.new('my_test')
        # two params
        options = {}
        set_conditional_charz_id(my_test, options)
        options[:id].should == nil
        # one param
        options = { parent_test_name: :my_test }
        set_conditional_charz_id(my_test, options)
        options[:id].should == nil
      end
    end

    it 'does nothing if charz is active but not result dependent' do
      Flow.create interface: 'MyCharzInterface' do
        my_test = MyTest.new('my_test')
        charz_on :my_profile, { on_result: nil }
        # two params
        options = {}
        set_conditional_charz_id(my_test, options)
        options[:id].should == nil
        # one param
        options = { parent_test_name: :my_test }
        set_conditional_charz_id(my_test, options)
        options[:id].should == nil
      end
    end

    it 'doesnt overwrite existing ID' do
      Flow.create interface: 'MyCharzInterface' do
        my_test = MyTest.new('my_test')
        charz_on :my_profile
        # two params
        options = { id: :existing_id }
        set_conditional_charz_id(my_test, options)
        options[:id].should == :existing_id
        # one param
        options = { id: :existing_id, parent_test_name: :my_test }
        set_conditional_charz_id(my_test, options)
        options[:id].should == :existing_id
      end
    end
  end


end
