module OrigenTesters
  MAJOR = 0
  MINOR = 52
  BUGFIX = 11
  DEV = nil
  VERSION = [MAJOR, MINOR, BUGFIX].join(".") + (DEV ? ".pre#{DEV}" : '')
end
