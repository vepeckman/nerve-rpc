import asyncHttpServer, asyncdispatch, json, ../utils
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
      await req.clientJs("tests/multipleServices")
    of "/":
      await req.indexHtml()
    else:
      await req.respond(Http404, "Not Found")

  result = cb

waitFor server.serve(Port(1234), generateCb())
