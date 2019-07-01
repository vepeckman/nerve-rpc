import asyncHttpServer, asyncdispatch, json, options
import personService, greetingService, fileService, nerve/utils

let server = newAsyncHttpServer()

proc cb(req: Request) {.async.} =
  let body = req.body
  case req.url.path
  of PersonService.rpcUri:
    await req.respond(Http200, $ await PersonService.routeRpc(body))
  of GreetingService.rpcUri:
    await req.respond(Http200, $ await GreetingService.routeRpc(body))
  of FileService.rpcUri:
    await req.respond(Http200, $ await FileService.routeRpc(body))
  of "/client.js":
    let headers = newHttpHeaders()
    headers["Content-Type"] = "application/javascript"
    await req.respond(Http200, readFile("tests/nimcache/client.js"), headers)
  of "/":
    await req.respond(Http200, """<html><head><meta charset="UTF-8"></head><body>Testing</body><script src="client.js"></script></html>""")
  else:
    await req.respond(Http404, "Not Found")

waitFor server.serve(Port(1234), cb)
