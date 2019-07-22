import asyncHttpServer, asyncdispatch, json
import newApi, nerve

let server = newAsyncHttpServer()

proc cb(req: Request) {.async.} =
  let rpcServer = Hello.newServer()
  let body = req.body
  case req.url.path
  of "/rpc":
    await req.respond(Http200, $ await Hello.routeRpc(rpcServer, body))
  of "/client.js":
    let headers = newHttpHeaders()
    headers["Content-Type"] = "application/javascript"
    await req.respond(Http200, readFile("tests/nimcache/newClient.js"), headers)
  of "/":
    await req.respond(Http200, """<html><head><meta charset="UTF-8"></head><body>Testing</body><script src="client.js"></script></html>""")
  else:
    await req.respond(Http404, "Not Found")

waitFor server.serve(Port(1234), cb)
