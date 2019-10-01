import json
import nerve, nerve/promises, nerve/websockets
configureNerve({
  MainService: sckFull
})
import services/main, itests/mainSuite

when defined(js):
  const host = ""
else:
  const host = "http://127.0.0.1:1234"

const wsHost = "ws://127.0.0.1:1234/ws"

let mainServer = MainService.newServer()


proc main() {.async.} =
  let mainHttp = MainService.newHttpClient(host)
  await runMainSuite(mainHttp)
  let ws = await newWebSocket(wsHost)
  proc serveWs(req: JsonNode) {.async.} =
    await ws.sendResponse(await MainService.routeRpc(mainServer, req))
  ws.onRequestReceived(serveWs)
  let mainWs = MainService.newClient(newWsDriver(ws))
  await runMainSuite(mainWs)


when defined(js):
  discard main()
else:
  waitFor main()
