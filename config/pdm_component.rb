class Testers_Application
  # An instance of this class is pre-instantiated at: Origen.app.pdm_component
  class PDMComponent

    include Origen::PDM

    def initialize(options={})
      @pdm_use_test_system = true       # Set this to false to deploy to live PDM
      #@pdm_initial_version_number = 2  # Only set this if starting from an pre-existing component

      @pdm_part_name = "Testers"
      @pdm_part_type = "software"
      @pdm_vc_type = "generator"
      @pdm_functional_category = "software|unclassifiable"
      @pdm_version = Origen.app.version
      @pdm_support_analyst = "Daniel Hadad (ra6854)"
      @pdm_security_owner = "Daniel Hadad (ra6854)"
      @pdm_owner = "Daniel Hadad (ra6854)"
      @pdm_design_manager = "Daniel Hadad (ra6854)"
      @pdm_cm_version = Origen.app.version
      @pdm_cm_path = "sync://sync-15088:15088/Projects/common_tester_blocks/origen_blocks/tester/Testers"
    end

  end
end
