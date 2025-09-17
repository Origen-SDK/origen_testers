module OrigenTesters
  MAJOR = 0
  MINOR = 52
  BUGFIX = 13
  DEV = nil
  VERSION = [MAJOR, MINOR, BUGFIX].join(".") + (DEV ? ".pre#{DEV}" : '')
end
