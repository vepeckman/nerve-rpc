import nerve, nerve/promises
import nerve/drivers, nerve/websockets
configureNerve({
  HelloService: sckClient,
  ViewService: sckServer
})
import helloService, viewService

proc serveView(ws: WebSocket) {.async.} =
  let view = ViewService.newServer()
  while true:
    let req = await ws.receiveRequest()
    await ws.sendResponse(await ViewService.routeRpc(view, req))

proc main() {.async.} =
  let ws = await newWebSocket("ws://127.0.01:1234/ws")
  let hello = HelloService.newClient(newWsDriver(ws))
  discard serveView(ws)
  echo await hello.greet()

when not defined(js):
  waitFor main()
else:
  discard main()
