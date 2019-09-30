import nerve

when defined(isClient):
  configureNerve({ OneFile:  sckClient })
else:
  configureNerve({ OneFile:  sckServer })

service OneFile, "/api":

  serverImports(asyncHttpServer, ../utils)

  proc greet(name = "world"): Future[string] = fwrap("Hello " & name)

  server:
    let server = newAsyncHttpServer()

    proc generateCb(): proc (req: Request): Future[void] {.gcsafe.} =
      let oneFile = OneFile.newServer()

      proc cb(req: Request) {.async, gcsafe.} =
        let body = req.body
        case req.url.path
        of OneFile.rpcUri:
          await req.respond(Http200, $ await OneFile.routeRpc(oneFile, body))
        of "/client.js":
          await req.clientJs("tests/oneFile", "oneFile.js")
        of "/":
          await req.indexHtml()
        else:
          await req.respond(Http404, "Not Found")

      result = cb

    waitFor server.serve(Port(1234), generateCb())

  client:
    proc main() {.async.} =
      when defined(js):
        const host = ""
      else:
        const host = "http://127.0.0.1:1234"

      let oneFile = OneFile.newHttpClient(host)

      echo await oneFile.greet("Nerve")
    
    when defined(js):
      discard main()
    else:
      waitFor main()
