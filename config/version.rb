module Testers
  MAJOR = 0
  MINOR = 3
  BUGFIX = 0
  DEV = 43

  VERSION = [MAJOR, MINOR, BUGFIX].join(".") + (DEV ? ".pre#{DEV}" : '')
end
