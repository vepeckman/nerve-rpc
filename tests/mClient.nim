import ../src/current/fetch
import api
import unittest, sugar, jsffi

var console {. importc, nodecl .}: JsObject
suite "Sanity":

  test "Basic":
    discard hello("nic")
      .then((greeting: string) => console.log(greeting))
