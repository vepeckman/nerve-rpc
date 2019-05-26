import ../src/current/fetch
import api
import sugar, jsffi, asyncjs, unittest, macros

var console {. importc, nodecl .}: JsObject


proc main() {.async.} =
  suite "Sanity":

    test "Hello":
      let msg = await hello("Nic")
      check(msg == "Hello Nic")


discard main()
