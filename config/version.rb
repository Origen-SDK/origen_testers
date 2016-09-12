module OrigenTesters
  MAJOR = 0
  MINOR = 8
  BUGFIX = 0
  DEV = 0

  VERSION = [MAJOR, MINOR, BUGFIX].join(".") + (DEV ? ".pre#{DEV}" : '')
end
