import json
import nerve, nerve/promises, nerve/websockets
import services/[main, model, view, controller], itests/[mainSuite, mvcSuite]

when defined(js):
  const host = ""
else:
  const host = "http://127.0.0.1:1234"

const wsHost = "ws://127.0.0.1:1234/ws"

let mainServer = MainService.newServer()

proc serveWs(ws: WebSocket, viewServer: ViewService.rpcType): auto =
  result = proc (req: JsonNode) {.async.} =
    if req["uri"].getStr() == mainServer.uri:
      await ws.sendResponse(await mainServer.routeRpc(req))
    if req["uri"].getStr() == viewServer.uri:
      await ws.sendResponse(await viewServer.routeRpc(req))

proc main() {.async.} =
  let mainHttp = MainService.newHttpClient(host)
  await runMainSuite(mainHttp)

  let ws = await newWebSocket(wsHost)
  let mainWs = MainService.newWsClient(ws)
  let viewData = ViewData(html: "hello world")
  let viewServer = ViewService.newServer(viewData)
  let controllerClient = ControllerService.newClient(newWsDriver(ws))
  ws.onRequestReceived(serveWs(ws, viewServer))

  await runMainSuite(mainWs)
  await runMvcClientSuite(viewServer, controllerClient, viewData)

when defined(js):
  discard main()
else:
  waitFor main()
