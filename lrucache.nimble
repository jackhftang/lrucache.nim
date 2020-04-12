# Package

version       = "1.0.0"
author        = "Jack Tang"
description   = "Least recently used (LRU) cache"
license       = "MIT"
srcDir        = "src"



# Dependencies

requires "nim >= 1.0.0"


task docgen, "generate docs":
  exec "nim doc --out:docs/index.html src/lrucache.nim"