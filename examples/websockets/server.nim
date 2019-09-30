import asynchttpserver, asyncdispatch, json, ../utils
import nerve, nerve/websockets

configureNerve({
  HelloService: sckServer,
  ViewService: sckClient
})

import helloService, viewService

let server = newAsyncHttpServer()

proc generateCb(): proc (req: Request): Future[void] {.gcsafe.} =
  let hello = HelloService.newServer()

  proc serveHello(ws: WebSocket) {.async.} =
    while true:
      let req = await ws.receiveRequest()
      await ws.sendResponse(await HelloService.routeRpc(hello, req))

  proc cb(req: Request) {.async, gcsafe.} =
    let body = req.body
    case req.url.path
    of "/ws":
      var ws = await newWebSocket(req)
      discard serveHello(ws)
      var view = ViewService.newClient(newWsDriver(ws))
      echo await view.newMessage("hello there")
    of HelloService.rpcUri:
      await req.respond(Http200, $ await HelloService.routeRpc(hello, body))
    of "/client.js":
      await req.clientJs("tests/websockets")
    of "/":
      await req.indexHtml()
    else:
      await req.respond(Http404, "Not Found")

  result = cb

waitFor server.serve(Port(1234), generateCb())
