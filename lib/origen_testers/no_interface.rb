module OrigenTesters
  # Origen will instantiate this interface if the application doesn't define one,
  # this allows test flows to be generated only
  class NoInterface
    include OrigenTesters::ProgramGenerators
  end
end
