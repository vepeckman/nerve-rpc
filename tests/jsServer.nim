import nerve
import json, nerve/promises
configureNerve({PersonService: sckServer})

import personService


let req = """
{"jsonrpc":"2.0","id":0,"method":"add","params":{"x":2,"y":3}}
"""

# var console {. importc, nodecl .} : JsObject

proc main() {. async .} =
  let server = PersonService.newServer()
  let resp = await PersonService.routeRpc(server, req)
  echo($ resp)

discard main()
