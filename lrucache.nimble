# Package

version       = "1.1.4"
author        = "Jack Tang"
description   = "Least recently used (LRU) cache"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.0.0"

proc updateNimbleVersion(ver: string) =
  let fname = "lrucache.nimble"
  let txt = readFile(fname)
  var lines = txt.split("\n")
  for i, line in lines:
    if line.startsWith("version"): 
      let s = line.find('"')
      let e = line.find('"', s+1)
      lines[i] = line[0..s] & ver & line[e..<line.len]
      break
  writeFile(fname, lines.join("\n"))

task version, "update version":
  # last params as version
  let ver = paramStr( paramCount() )
  if ver == "version": 
    echo version
  else:
    withDir thisDir(): 
      updateNimbleVersion(ver)

task docgen, "generate docs":
  exec "nim doc --out:docs/index.html src/lrucache.nim"

task release_patch, "release with patch increment":
  exec "release-it --ci -i patch"

task release_minor, "releaes with minor increment":
  exec "release-it --ci -i minor"

task release_major, "release with major increment":
  exec "release-it --ci -i major"