import macros
import common

when defined(js):
  import jsffi, asyncjs

  type wstring* = cstring

  proc fetch*(uri: cstring): Future[JsObject] {. importc .}
  proc fetch*(uri: cstring, data: JsObject): Future[JsObject] {. importc .}
  proc then*[T, R](promise: Future[T], next: proc (data: T): Future[R]): Future[R] {. importcpp: "#.then(@)" .}
  proc then*[T, R](promise: Future[T], next: proc (data: T): R): Future[R] {. importcpp: "#.then(@)" .}
  proc then*[T](promise: Future[T], next: proc(data: T)): Future[void] {. importcpp: "#.then(@)" .}
  proc catch*[T, R](promise: Future[T], next: proc (data: T): Future[R]): Future[R] {. importcpp: "#.catch(@)" .}
  proc catch*[T, R](promise: Future[T], next: proc (data: T): R): Future[R] {. importcpp: "#.catch(@)" .}
  proc catch*[T](promise: Future[T], next: proc(data: T)): Future[void] {. importcpp: "#.catch(@)" .}

  export asyncjs

else:
  import json, asyncdispatch

  type wstring* = string

  proc fwrap*[T](it: T): Future[T] =
    result = newFuture[T]()
    result.complete(it)

  macro rpcUri*(rpc: RpcService): untyped =
    let rpcName = rpc.strVal()
    let uriConst = rpcName.rpcUriConstName
    result = quote do:
      `uriConst`

  macro routeRpc*(rpc: RpcService, req: JsonNode): untyped =
    let rpcName = rpc.strVal()
    let routerProc = rpcName.rpcRouterProcName
    result = quote do:
      `routerProc`(`req`)

  macro routeRpc*(rpc: RpcService, req: string): untyped =
    let rpcName = rpc.strVal()
    let routerProc = rpcName.rpcRouterProcName
    result = quote do:
      `routerProc`(`req`)

  export asyncdispatch, RpcService
