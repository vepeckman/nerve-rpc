import macros
import json

type RpcServer* = object of RootObj
  uri*: string

proc rpcRouterProcName*(name: NimNode): NimNode =
  let nameStr = strVal(name)
  result = ident("NerveRpc" & nameStr & "Router")

macro routeRpc*(rpc: RpcServer, req: untyped): untyped =
  let routerProc = rpc.rpcRouterProcName
  result = quote do:
    `routerProc`(parseJson(`req`))

proc rpcServiceName*(name: NimNode): NimNode =
  let nameStr = strVal(name)
  result = ident("NerveRpc" & nameStr & "Service")

proc rpcServiceType*(name: NimNode, procs: seq[NimNode]): NimNode =
  let typeName = rpcServiceName(name)
  var procFields = nnkRecList.newTree()
  for p in procs:
    var procType = nnkProcTy.newTree()
    procType.add(p.findChild(it.kind == nnkFormalParams))
    procType.add(newEmptyNode())
    procFields.add(
      newIdentDefs(postfix(p[0].basename, "*"), procType)
    )

  result = quote do:
    type `typeName`* = object of RpcServer
  result[0][2][2] = procFields

proc rpcServiceObject*(name: NimNode, procs: seq[NimNode], uri = "rpc"): NimNode =
  let typeName = rpcServiceName(name)
  result = quote do:
    var `name`* = `typeName`(uri: `uri`)
  for p in procs:
    var field = newColonExpr(p[0].basename, p[0].basename)
    result[0][2].add(field)
