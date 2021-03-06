# Package

version       = "1.5.0"
author        = "Thiago Navarro"
description   = "Bluesoft Cosmos extractor"
license       = "gpl-3.0-only"
srcDir        = "src"

# Dependencies

requires "nim >= 1.5.1"
requires "scraper"
requires "https://gitlab.com/lurlo/useragent"

task gen_docs, "Generates the documentation":
  exec "nim doc --project --out:docs src/bluesoftcosmos.nim"
