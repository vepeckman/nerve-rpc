import asynchttpserver, asyncdispatch, ws, json, ../utils
import nerve

configureNerve({HelloService: sckServer})

import helloService

let server = newAsyncHttpServer()

proc generateCb(): proc (req: Request): Future[void] {.gcsafe.} =
  let hello = HelloService.newServer()

  proc cb(req: Request) {.async, gcsafe.} =
    let body = req.body
    case req.url.path
    of "/ws":
      var ws = await newWebSocket(req)
      while ws.readyState == Open:
        try:
          let packet = await ws.receiveStrPacket()
          await ws.send($ await HelloService.routeRpc(hello, packet))
        except:
          echo "connection lost"
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
