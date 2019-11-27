import asyncHttpServer, asyncdispatch, json, utils
import nerve, nerve/websockets
import services/[main, view, controller, model], itests/mainSuite

let server = newAsyncHttpServer()

proc generateCb(): proc (req: Request): Future[void] {.gcsafe.} =

  let mainServer = MainService.newServer()

  proc runWs(req: Request) {.async.} =
    let ws = await newWebSocket(req)

    let mainClient = MainService.newClient(newWsDriver(ws))
    let appData = AppData(data: "asdf")
    let modelServer = ModelService.newServer(appData)
    let viewClient = ViewService.newClient(newWsDriver(ws))
    let controllerServer = ControllerService.newServer(viewClient = viewClient, modelServer = modelServer)

    proc serveWs(msg: auto) {.async.} =
      if msg["uri"].getStr() == mainServer.uri:
        await ws.sendResponse(await mainServer.routeRpc(msg))
      if msg["uri"].getStr() == controllerServer.uri:
        await ws.sendResponse(await controllerServer.routeRpc(msg))
      if msg["uri"].getStr() == modelServer.uri:
        await ws.sendResponse(await modelServer.routeRpc(msg))

    ws.onRequestReceived(serveWs)

    await runMainSuite(mainClient)

  proc cb(req: Request) {.async, gcsafe.} =
    let body = req.body
    case req.url.path
    of MainService.rpcUri:
      await req.respond(Http200, $ await mainServer.routeRpc(body))
    of "/ws":
      await runWs(req)
    of "/client.js":
      await req.clientJs("tests")
    of "/":
      await req.indexHtml()
    else:
      await req.respond(Http404, "Not Found")

  result = cb

waitFor server.serve(Port(1234), generateCb())
