import ../src/current/fetch
import api
import sugar, jsffi, asyncjs, unittest, macros

var console {. importc, nodecl .}: JsObject


proc main() {.async.} =
  suite "Sanity":

    test "Hello":
      let msg = await example.hello("Nic")
      check(msg == "Hello Nic")

    test "Person":
      let person = await example.newPerson("Nic", 24)
      check(person.name == "Nic")


discard main()
