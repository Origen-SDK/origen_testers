module OrigenTesters
  MAJOR = 0
  MINOR = 48
  BUGFIX = 1
  DEV = nil
  VERSION = [MAJOR, MINOR, BUGFIX].join(".") + (DEV ? ".pre#{DEV}" : '')
end
