import types, web, promises, clientRuntime

var currentId {.threadvar.} : int
currentId = 0
proc genId(): int =
  currentId = currentId + 1
  result = currentId

when not defined(js):
  import httpClient, ws

  proc newHttpDriver*(uri: string): NerveDriver =
    let client = newAsyncHttpClient()
    result = proc (req: JsonNode): Future[JsonNode] {.async.} =
      let res = await client.postContent(uri, $ req)
      result = res.respToJson()

  proc newWsDriver*(ws: WebSocket): NerveDriver =
    result = proc (req: JsonNode): Future[JsonNode] {.async.} =
      let id = $ genId()
      req["id"] = % id
      await ws.send($ req)
      var respReceived = false
      while not respReceived:
        let resp = parseJson(await ws.receiveStrPacket())
        if resp["id"].getStr() == id:
          respReceived = true
          result = resp
      
else:
  import jsffi

  proc newHttpDriver*(uri: string): NerveDriver =
    result = proc (req: JsonNode): Future[JsonNode] =
      let msg = newJsObject()
      msg["method"] = cstring"POST"
      msg["body"] = cstring($ req)
      result = fetch(cstring(uri), msg)
        .then(handleFetchResponse)

  proc newWsDriver*(ws: JsObject): NerveDriver =
    result = proc (req: JsonNode): Future[JsonNode] =
      result = newPromise[JsonNode](proc (resolve: proc (response: JsonNode)) =
        let id = $ genId()
        req["id"] = % id
        ws.send($ req)
        let cb = proc (event: JsObject) =
          let data: cstring = cast[cstring](event.data)
          let resp = parseJson($ data)
          if resp["id"].getStr() == id:
            resolve(resp)
        let eventListener = ws.addEventListener(cstring"message", cb)
      )
