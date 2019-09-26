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
  import jsffi, tables

  proc newHttpDriver*(uri: string): NerveDriver =
    result = proc (req: JsonNode): Future[JsonNode] =
      let msg = newJsObject()
      msg["method"] = cstring"POST"
      msg["body"] = cstring($ req)
      result = fetch(cstring(uri), msg)
        .then(handleFetchResponse)

  proc WebSocket(uri: cstring): JsObject {. importc, nodecl .}

  type NerveWebSocket* = ref object
    js: Future[JsObject]
    openPromises: TableRef[string, proc (resp: JsonNode)]

  proc newWebSocket*(uri: cstring): NerveWebSocket =
    var ws = NerveWebSocket(js: nil, openPromises: newTable[string, proc (resp: JsonNode)]())
    var jsWs = jsNew WebSocket(uri)

    let cb = proc (event: JsObject) =
      let data: cstring = cast[cstring](event.data)
      let resp = parseJson($ data)
      var fulfilled: seq[string] = @[]
      for idx in ws.openPromises.keys:
        if resp["id"].getStr() == idx:
          ws.openPromises[idx](resp)
          fulfilled.add(idx)
      for idx in fulfilled:
        ws.openPromises.del(idx)

    jsWs.addEventListener(cstring"message", cb)

    ws.js = newPromise[JsObject](proc (resolve: proc (w: JsObject)) =
      let openCb = proc () = resolve(jsWs)
      jsWs.addEventListener(cstring"open", openCb)
    )

    result = ws


  proc send(ws: NerveWebSocket, req: JsonNode): Future[JsonNode] =
    return ws.js.then(proc (jsWs: JsObject): Future[JsonNode] =
      jsWs.send($ req)
      result = newPromise[JsonNode](proc (resolve: proc (response: JsonNode)) =
        ws.openPromises[req["id"].getStr()] = resolve
      )
    )

  proc newWsDriver*(ws: NerveWebSocket): NerveDriver =
    result = proc (req: JsonNode): Future[JsonNode] =
        let id = $ genId()
        req["id"] = % id
        result = ws.send(req)
