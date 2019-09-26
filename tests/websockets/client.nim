import nerve, nerve/promises
import nerve/drivers
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
    let ws = newWebSocket(cstring"ws://127.0.01:1234/ws")
    let hello = HelloService.newClient(newWsDriver(ws))
    echo await hello.greet()

when not defined(js):
  waitFor main()
else:
  discard main()
