import httpbeast, asyncdispatch, json, options
import ../api

proc cb(req: Request) {.async.} =
  case req.path.get()
  of "/rpc":
    req.send(Http200, $handler(parseJson(req.body.get())))
  of "/client.js":
    req.send(readFile("tests/nimcache/client.js"))
  of "/":
    req.send("""<html><head></head><body>Testing</body><script src="client.js"></script></html>""")
  else:
    req.send(Http404)

run(cb, Settings(port: Port(1234), bindAddr: ""))
