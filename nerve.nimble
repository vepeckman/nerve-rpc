# Package

version       = "0.1.1"
author        = "nepeckman"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 0.19.6"

task itests, "Runs intergration tests":
  exec "nimble js tests/client.nim"
  exec "nimble c -r tests/server.nim"
