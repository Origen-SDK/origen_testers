module OrigenTesters
  MAJOR = 0
  MINOR = 19
  BUGFIX = 2
  DEV = nil

  VERSION = [MAJOR, MINOR, BUGFIX].join(".") + (DEV ? ".pre#{DEV}" : '')
end
