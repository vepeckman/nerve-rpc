import json
import types, promises, clientRuntime

var currentId {.threadvar.} : int
currentId = 0
proc genId(): int =
  currentId = currentId + 1
  result = currentId

when not defined(js):
  import httpClient

  proc newHttpDriver*(uri: string): NerveDriver =
    ## A Nerve Driver that sends requests over HTTP
    let client = newAsyncHttpClient()
    result = proc (req: JsonNode): Future[JsonNode] {.async.} =
      let res = await client.postContent(uri, $ req)
      result = res.respToJson()
      
else:
  import jsffi

  proc newHttpDriver*(uri: string): NerveDriver =
    ## A Nerve Driver that sends requests over HTTP
    result = proc (req: JsonNode): Future[JsonNode] =
      let msg = newJsObject()
      msg["method"] = cstring"POST"
      msg["body"] = cstring($ req)
      result = fetch(cstring(uri), msg)
        .then(handleFetchResponse)


import websockets

proc newWsDriver*(ws: WebSocket): NerveDriver =
  ## A Nerve Driver that sends requests over a websocket
  result = proc (req: JsonNode): Future[JsonNode] =
      let id = $ genId()
      req["id"] = % id
      result = ws.sendRequest(req)
