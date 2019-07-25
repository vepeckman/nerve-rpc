import asyncHttpServer, asyncdispatch, json
import personService, greetingService, fileService, nerve

let server = newAsyncHttpServer()

proc generateCb(): proc (req: Request): Future[void] {.gcsafe.} =

  let personServer = PersonService.newServer()
  let greetingServer = GreetingService.newServer(count = 1)
  let fileServer = FileService.newServer()

  proc cb(req: Request) {.async, gcsafe.} =
    let body = req.body
    case req.url.path
    of PersonService.rpcUri:
      await req.respond(Http200, $ await PersonService.routeRpc(personServer, body))
    of GreetingService.rpcUri:
      await req.respond(Http200, $ await GreetingService.routeRpc(greetingServer, body))
    of FileService.rpcUri:
      await req.respond(Http200, $ await FileService.routeRpc(fileServer, body))
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