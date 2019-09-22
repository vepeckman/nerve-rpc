import nerve

when not defined(js):
  import ws

when defined(isClient):
  configureNerve({ OneFile:  sckClient })
else:
  configureNerve({ OneFile:  sckServer })

service OneFile, "/api":

  serverImports(asyncHttpServer)

  proc greet(name = "world"): Future[string] = fwrap("Hello " & name)

  server:
    let server = newAsyncHttpServer()

    proc generateCb(): proc (req: Request): Future[void] {.gcsafe.} =
      let oneFile = OneFile.newServer()

      proc cb(req: Request) {.async, gcsafe.} =
        let body = req.body
        case req.url.path
        of "/ws":
          var ws = await newWebSocket(req)
          while ws.readyState == Open:
            try:
              let packet = await ws.receiveStrPacket()
              await ws.send($ await OneFile.routeRpc(oneFile, packet))
            except:
              echo "connection lost"
        of OneFile.rpcUri:
          await req.respond(Http200, $ await OneFile.routeRpc(oneFile, body))
        of "/client.js":
          let headers = newHttpHeaders()
          headers["Content-Type"] = "application/javascript"
          await req.respond(Http200, readFile("tests/nimcache/client.js"), headers)
        of "/":
          await req.respond(Http200, """<html><head><meta charset="UTF-8"></head><body>Testing</body><script src="client.js"></script></html>""")
        else:
          await req.respond(Http404, "Not Found")

      result = cb

    waitFor server.serve(Port(1234), generateCb())

  client:
    proc main() {.async.} =
      when not defined(js):
        let ws = await newWebSocket("ws://127.0.01:1234/ws")
      else:
        {. emit: "var ws = new WebSocket('ws://127.0.01:1234/ws');" .}
        var ws {. importc, nodecl .}: JsObject
        let openCb = proc () {.async.} =
          echo "connection made"
          let oneFile = OneFile.newClient(newWsDriver(ws))
          echo await oneFile.greet("Nerve")

        ws.addEventListener(cstring"open", openCb)

    when not defined(js):
      waitFor main()
    else:
      discard main()
