import httpbeast, asyncdispatch, json, options
import personService, greetingService, fileService, nerve/utils

template routeRpc(service: RpcServer, req: Request): untyped =
  service.routeRpc(if req.body.isSome: req.body.get() else: "")

proc cb(req: Request) {.async.} =
  case req.path.get()
  of PersonService.rpcUri:
    req.send($ await PersonService.routeRpc(req))
  of GreetingService.rpcUri:
    req.send($ await GreetingService.routeRpc(req))
  of FileService.rpcUri:
    req.send($ await FileService.routeRpc(req))
  of "/client.js":
    const headers = "Content-Type: application/javascript"
    req.send(Http200, readFile("tests/nimcache/client.js"), headers)
  of "/":
    req.send("""<html><head><meta charset="UTF-8"></head><body>Testing</body><script src="client.js"></script></html>""")
  else:
    req.send(Http404)

run(cb, Settings(port: Port(1234), bindAddr: ""))
