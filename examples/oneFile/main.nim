import nerve

service HelloService, "/api":

  proc greet(name = "world"): Future[string] = futureWrap("Hello " & name)

  server:
    import asyncHttpServer
    let server = newAsyncHttpServer()

    proc handler(): proc (req: Request): Future[void] {.gcsafe.} =
      let helloServer = HelloService.newServer()

      result = proc (req: Request) {.async, gcsafe.} =
        let body = req.body
        case req.url.path
        of HelloService.rpcUri:
          await req.respond(Http200, $ await helloServer.routeRpc(body))
        of "/client.js":
          let headers = newHttpHeaders()
          headers["Content-Type"] = "application/javascript"
          await req.respond(Http200, readFile("examples/oneFile/nimcache/main.js"), headers)
        of "/":
          await req.respond(Http200, """<html><head><meta charset="UTF-8"></head><body>Testing</body><script src="client.js"></script></html>""")
        else:
          await req.respond(Http404, "Not Found")

    waitFor server.serve(Port(1234), handler())

  client:
    proc main() {.async.} =
      when defined(js):
        const host = ""
      else:
        const host = "http://127.0.0.1:1234"

      let helloClient = HelloService.newHttpClient(host)
      echo await helloClient.greet("Nerve")
    
    when defined(js):
      discard main()
    else:
      waitFor main()
