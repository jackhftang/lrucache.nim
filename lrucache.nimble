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

task release_patch, "release with patch increment":
  exec "release-it --ci -i patch"

task release_minor, "releaes with minor increment":
  exec "release-it --ci -i minor"

task release_major, "release with major increment":
  exec "release-it --ci -i major"