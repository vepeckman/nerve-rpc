import macros
import common

when defined(js):
  import jsffi, asyncjs

  type kstring* = cstring

  proc fetch*(uri: cstring): Future[JsObject] {. importc .}
  proc fetch*(uri: cstring, data: JsObject): Future[JsObject] {. importc .}
  proc then*[T, R](promise: Future[T], next: proc (data: T): Future[R]): Future[R] {. importcpp: "#.then(@)" .}
  proc then*[T, R](promise: Future[T], next: proc (data: T): R): Future[R] {. importcpp: "#.then(@)" .}
  proc then*[T](promise: Future[T], next: proc(data: T)): Future[void] {. importcpp: "#.then(@)" .}

  proc Boolean*(o: JsObject): bool {. importc .}
  var JSON* {. importc, nodecl .}: JsObject

  type
    InvalidResponseError = ref object of CatchableError
    RpcError = ref object of CatchableError

  proc respJson*(data: JsObject): JsObject {. importcpp: "#.json()" .}
  proc respToJson*(resp: JsObject): JsObject =
    if Boolean(resp.ok):
      return respJson(resp)
    let msg = "Invalid Response: Server responsed with code " & $to(resp.status, int)
    raise InvalidResponseError(msg: msg)
  proc handleRpcResponse*[T](rpcResponse: JsObject): T =
    let error = rpcResponse["error"]
    if Boolean(error):
      let msg = $error.message.to(cstring) & ": " & $error.data.msg.to(cstring) & "\n" & $error.data.stackTrace.to(cstring) & "\n"
      raise RpcError(msg: msg)
    rpcResponse["result"].to(T)


  export asyncjs

else:
  import json, asyncdispatch

  type kstring* = string

  macro rpcUri*(rpc: RpcServer): untyped =
    let uriConst = rpc.rpcUriConstName
    result = quote do:
      `uriConst`

  macro routeRpc*(rpc: RpcServer, req: JsonNode): untyped =
    let routerProc = rpc.rpcRouterProcName
    result = quote do:
      `routerProc`(`req`)

  macro routeRpc*(rpc: RpcServer, req: string): untyped =
    let routerProc = rpc.rpcRouterProcName
    result = quote do:
      `routerProc`(`req`)

  export asyncdispatch, RpcServer
