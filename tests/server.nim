import httpbeast, asyncdispatch, json, options
import api

proc cb(req: Request) {.async.} =
  case req.path.get()
  of "/rpc":
    req.send(Http200, $handler(parseJson(req.body.get())))
  of "/client.js":
    const headers = "Content-Type: application/javascript"
    req.send(Http200, readFile("tests/nimcache/client.js"), headers)
  of "/":
    req.send("""<html><head><meta charset="UTF-8"></head><body>Testing</body><script src="client.js"></script></html>""")
  else:
    req.send(Http404)

run(cb, Settings(port: Port(1234), bindAddr: ""))
