module OrigenTesters
  MAJOR = 0
  MINOR = 51
  BUGFIX = 4
  DEV = nil
  VERSION = [MAJOR, MINOR, BUGFIX].join(".") + (DEV ? ".pre#{DEV}" : '')
end
