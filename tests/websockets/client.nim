import nerve, nerve/promises
configureNerve({HelloService: sckClient})
import helloService

when not defined(js):
  import ws
else:
  import jsffi

proc main() {.async.} =
  when not defined(js):
    let ws = await newWebSocket("ws://127.0.01:1234/ws")
    let hello = HelloService.newClient(newWsDriver(ws))
    echo await hello.greet("Nerve")
  else:
    {. emit: "var ws = new WebSocket('ws://127.0.01:1234/ws');" .}
    var ws {. importc, nodecl .}: JsObject
    let openCb = proc () {.async.} =
      echo "connection made"
      let hello = HelloService.newClient(newWsDriver(ws))
      echo await hello.greet("Nerve")

    ws.addEventListener(cstring"open", openCb)

when not defined(js):
  waitFor main()
else:
  discard main()
