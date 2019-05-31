import httpbeast, asyncdispatch, json, options
import api, current/utils

proc cb(req: Request) {.async.} =
  case req.path.get()
  of example.rpcUri:
    let rpcRequest = req.body.get().parseJson()
    req.send(Http200, $example.routeRpc(rpcRequest))
  of "/client.js":
    const headers = "Content-Type: application/javascript"
    req.send(Http200, readFile("tests/nimcache/client.js"), headers)
  of "/":
    req.send("""<html><head><meta charset="UTF-8"></head><body>Testing</body><script src="client.js"></script></html>""")
  else:
    req.send(Http404)

run(cb, Settings(port: Port(1234), bindAddr: ""))