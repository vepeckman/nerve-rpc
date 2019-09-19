import nerve

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
        echo req.url.path
        case req.url.path
        of OneFile.rpcUri:
          await req.respond(Http200, $ await OneFile.routeRpc(oneFile, body))
        else:
          await req.respond(Http404, "Not Found")

      result = cb

    waitFor server.serve(Port(1234), generateCb())

  client:
    proc main() {.async.} =
      let oneFile = OneFile.newHttpClient("http://127.0.0.1:1234")

      echo await oneFile.greet("Nerve")
    
    waitFor main()
