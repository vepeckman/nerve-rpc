import asynchttpserver, asyncdispatch, json
import ../api

var server = newAsyncHttpServer()
proc cb(req: Request) {.async.} =
  if req.url.path == "/rpc":
    await req.respond(Http200, $handler(parseJson(req.body)))
  else:
    await req.respond(Http200, "Hello world")

waitFor server.serve(Port(1234), cb)
