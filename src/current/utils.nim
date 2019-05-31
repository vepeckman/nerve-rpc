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

  var JSON* {. importc, nodecl .}: JsObject
  proc respJson*(data: JsObject): JsObject {. importcpp: "#.json()" .}
  proc respToJson*(resp: JsObject): JsObject = respJson(resp)


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

  export asyncdispatch
