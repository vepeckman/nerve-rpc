import sequtils, tables, json, sugar
import promises

when defined(js):
  import jsffi

  proc NativeWebSocket(uri: cstring): JsObject {. importc: "WebSocket", nodecl .}

  type WebSocket* = ref object
    nativeSocket: JsObject
    requestResolvers: TableRef[string, proc (res: JsonNode)]
    receivers: seq[proc (res: JsonNode): Future[void]]

  proc newWebSocket*(uri: cstring): Future[WebSocket] =
    var ws = WebSocket(
      nativeSocket: jsNew NativeWebSocket(uri),
      requestResolvers: newTable[string, proc (res: JsonNode)](),
      receivers: @[]
    )
    let cb = proc (event: JsObject) =
      let data: cstring = cast[cstring](event.data)
      let message = parseJson($ data)
      if message.hasKey("result"):
        var fulfilled: seq[string] = @[]
        for idx in ws.requestResolvers.keys:
          if message["id"].getStr() == idx:
            ws.requestResolvers[idx](message)
            fulfilled.add(idx)
        for idx in fulfilled:
          ws.requestResolvers.del(idx)
      elif message.hasKey("method"):
        for listener in ws.receivers:
          discard listener(message)

    ws.nativeSocket.addEventListener(cstring"message", cb)

    result = newPromise[WebSocket](proc (resolve: proc (w: WebSocket)) =
      let openCb = proc () = resolve(ws)
      ws.nativeSocket.addEventListener(cstring"open", openCb)
    )

  proc sendRequest*(ws: WebSocket, req: JsonNode): Future[JsonNode] =
    ws.nativeSocket.send($ req)
    result = newPromise[JsonNode](proc (resolve: proc (response: JsonNode)) =
      ws.requestResolvers[req["id"].getStr()] = resolve
    )

  proc sendResponse*(ws: WebSocket, resp: JsonNode): Future[void] =
    ws.nativeSocket.send($ resp)
    result = newPromise[void](proc (res: proc ()) = res())

  proc onRequestReceived*(ws: WebSocket, cb: proc (res: JsonNode): Future[void]) =
    ws.receivers.add(cb)

  proc removeRequestListener*(ws: WebSocket, cb: proc (res: JsonNode): Future[void]) =
    ws.receivers = ws.receivers.filter((listener) => listener != cb)

else:
  import json, asynchttpserver
  from ws import nil

  type WebSocket* = ref object
    nativeSocket: ws.WebSocket
    isOpen: bool
    requestResolvers: TableRef[string, Future[JsonNode]]
    receivers: seq[proc (res: JsonNode): Future[void]]
    responseQueue: seq[JsonNode]

  proc receiveData(websocket: WebSocket) {.async.} =
    let socket = websocket.nativeSocket
    while socket.readyState == ws.Open:
      var packet: string
      try:
        packet = await ws.receiveStrPacket(socket)
      except:
        websocket.isOpen = false
        echo "connection lost"
      let message = parseJson(packet)
      if message.hasKey("result"):
        var fulfilled: seq[string] = @[]
        for idx in websocket.requestResolvers.keys:
          if message["id"].getStr() == idx:
            websocket.requestResolvers[idx].complete(message)
            fulfilled.add(idx)
        for idx in fulfilled:
          websocket.requestResolvers.del(idx)
      elif message.hasKey("method"):
        for listener in websocket.receivers:
          discard listener(message)

  proc newWebSocket*(uri: string): Future[WebSocket] {.async.} =
    let socket = await ws.newWebSocket(uri)
    var websocket = WebSocket(
      nativeSocket: socket,
      isOpen: true,
      requestResolvers: newTable[string, Future[JsonNode]](),
      receivers: @[],
      responseQueue: @[]
    )
    discard receiveData(websocket)
    result = websocket

  proc newWebSocket*(req: Request): Future[WebSocket] {.async.} =
    let socket = await ws.newWebSocket(req)
    var websocket = WebSocket(
      nativeSocket: socket,
      requestResolvers: newTable[string, Future[JsonNode]](),
      receivers: @[]
    )
    discard receiveData(websocket)
    result = websocket


  proc sendRequest*(websocket: WebSocket, req: JsonNode): Future[JsonNode] {.async.} =
    let socket = websocket.nativeSocket
    let f = newFuture[JsonNode]()
    websocket.requestResolvers[req["id"].getStr()] = f
    await ws.send(socket, $ req)
    result = await f

  proc sendResponse*(websocket: WebSocket, resp: JsonNode): Future[void] {.async.} =
    let socket = websocket.nativeSocket
    await ws.send(socket, $ resp)

  proc onRequestReceived*(ws: WebSocket, cb: proc (res: JsonNode): Future[void]) =
    ws.receivers.add(cb)

  proc removeRequestListener*(ws: WebSocket, cb: proc (res: JsonNode): Future[void]) =
    ws.receivers = ws.receivers.filter((listener) => listener != cb)

  proc isOpen*(websocket: Websocket): bool = websocket.isOpen
