import asyncHttpServer, asyncdispatch, json, utils
import nerve, nerve/websockets
import services/main, itests/mainSuite

let server = newAsyncHttpServer()

proc generateCb(): proc (req: Request): Future[void] {.gcsafe.} =

  let mainServer = MainService.newServer()


  proc cb(req: Request) {.async, gcsafe.} =
    let body = req.body
    case req.url.path
    of MainService.rpcUri:
      await req.respond(Http200, $ await MainService.routeRpc(mainServer, body))
    of "/ws":
      let ws = await newWebSocket(req)
      proc serveWs(req: auto) {.async.} =
        await ws.sendResponse(await MainService.routeRpc(mainServer, req))
      ws.onRequestReceived(serveWs)
      let mainClient = MainService.newClient(newWsDriver(ws))
      await runMainSuite(mainClient)
    of "/client.js":
      await req.clientJs("tests")
    of "/":
      await req.indexHtml()
    else:
      await req.respond(Http404, "Not Found")

  result = cb

waitFor server.serve(Port(1234), generateCb())
