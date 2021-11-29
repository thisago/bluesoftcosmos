# Package

version       = "0.1.0"
author        = "Luciano Lorenzo"
description   = "Bluesoft Cosmos extractor"
license       = "GPL-3"
srcDir        = "src"

# Dependencies

requires "nim >= 1.5.1"
requires "scraper"
requires "https://gitlab.com/lurlo/useragent"

task gen_docs, "Generates the documentation":
  exec "nim doc --project --out:docs src/bluesoftcosmos.nim"

bin = @["bluesoftcosmos"]
binDir = "build"

task build_release, "Builds the release version":
  exec "nimble -d:release build"
task build_danger, "Builds the danger version":
  exec "nimble -d:danger build"
task gen_docs, "Generates the documentation":
  exec "nim doc --project --out:docs src/bluesoftcosmos.nim"
