import ../src/current/fetch
import api
import sugar, jsffi, asyncjs, unittest, macros

var console {. importc, nodecl .}: JsObject


expandMacros:

  suite "Sanity":

    test "Basic":

      check(true == true)
