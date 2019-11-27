# Package

version       = "0.3.0"
author        = "nepeckman"
description   = "An RPC framework"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 0.19.6"
requires "ws"

task itests, "Runs intergration tests":
  exec "nimble js tests/client.nim"
  exec "nimble c -r tests/server.nim"
