import httpbeast, asyncdispatch, json, options
import personService, greetingService, fileService, current/utils

proc cb(req: Request) {.async.} =
  case req.path.get()
  of PersonService.rpcUri:
    let rpcRequest = req.body.get().parseJson()
    req.send($ await PersonService.routeRpc(rpcRequest))
  of GreetingService.rpcUri:
    let rpcRequest = req.body.get().parseJson()
    req.send($ await GreetingService.routeRpc(rpcRequest))
  of FileService.rpcUri:
    let rpcRequest = req.body.get().parseJson()
    req.send($ await FileService.routeRpc(rpcRequest))
  of "/client.js":
    const headers = "Content-Type: application/javascript"
    req.send(Http200, readFile("tests/nimcache/client.js"), headers)
  of "/":
    req.send("""<html><head><meta charset="UTF-8"></head><body>Testing</body><script src="client.js"></script></html>""")
  else:
    req.send(Http404)

run(cb, Settings(port: Port(1234), bindAddr: ""))
