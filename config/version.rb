module OrigenTesters
  MAJOR = 0
  MINOR = 8
  BUGFIX = 9
  DEV = nil

  VERSION = [MAJOR, MINOR, BUGFIX].join(".") + (DEV ? ".pre#{DEV}" : '')
end
