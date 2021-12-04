# Package

version       = "1.2.0"
author        = "Luciano Lorenzo"
description   = "Bluesoft Cosmos extractor"
license       = "gpl-3.0"
srcDir        = "src"

# Dependencies

requires "nim >= 1.5.1"
requires "scraper"
requires "https://gitlab.com/lurlo/useragent"

task gen_docs, "Generates the documentation":
  exec "nim doc --project --out:docs src/bluesoftcosmos.nim"
