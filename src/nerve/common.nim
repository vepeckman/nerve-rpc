import macros, tables
import types

const dispatchPrefix* = "NerveRpc"

proc networkProcName*(name: string): NimNode = ident("NerveNetwork" & name)

proc rpcRouterProcName*(name: string): NimNode = ident("NerveRpc" & name & "Router")

proc rpcUriConstName*(name: string): NimNode = ident("NerveRpc" & name & "Uri")

proc rpcUriConst*(name, uri: string): NimNode =
  let uriConst = name.rpcUriConstName()
  result = quote do:
    const `uriConst`* = `uri`

proc rpcServiceName*(name: string): NimNode = ident("NerveRpc" & name & "Object")

proc rpcServerFactoryProc*(name: string): NimNode = ident("NerveRpc" & name & "ServerFactory")

proc rpcClientFactoryProc*(name: string): NimNode = ident("NerveRpc" & name & "ClientFactory")

proc rpcServiceType*(name: string, procs: seq[NimNode]): NimNode =
  let typeName = rpcServiceName(name)
  var procFields = nnkRecList.newTree()
  for p in procs:
    var procType = nnkProcTy.newTree()
    procType.add(p.findChild(it.kind == nnkFormalParams))
    procType.add(nnkPragma.newTree(ident("gcsafe")))
    procFields.add(
      newIdentDefs(postfix(p[0].basename, "*"), procType)
    )

  result = quote do:
    type `typeName`* = object of RpcServiceInst
  result[0][2][2] = procFields

proc rpcServiceObject*(name: string, procs: Table[string, NimNode], kind: RpcServiceKind, uri: string): NimNode =
  let typeName = rpcServiceName(name)
  let kindName = ident($kind)
  let routerName = rpcRouterProcName(name)
  result = quote do:
    block:
      var service = `typeName`(kind: `kindName`, uri: `uri`)
      service.nerveStrRpcRouter = proc (req: string): Future[JsonNode] = `routerName`(service, req)
      service.nerveJsonRpcRouter = proc (req: JsonNode): Future[JsonNode] = `routerName`(service, req)
      service
  for pName in procs.keys:
    var field = newColonExpr(procs[pName][0].basename, ident(pName))
    result[1][0][0][2].add(field)

proc paramType*(param: NimNode): NimNode =
  # Either returns the type node of the param
  # or creates a node that gets the type of default value
  let defaultIdx = param.len - 1
  let typeIdx = param.len - 2
  if param[typeIdx].kind == nnkEmpty:
    var defaultParam = param[defaultIdx]
    result = quote do:
      typeof(`defaultParam`)
  else:
    result = param[typeIdx]

proc getParams*(formalParams: NimNode): seq[Table[string, NimNode]] =
  # Find all the parameters and build a table with needed information
  assert(formalParams[0].len > 1, "RPC procs need to return a future")
  assert(formalParams[0][0].strVal == "Future", "RPC procs need to return a future")
  for param in formalParams:
    if param.kind == nnkIdentDefs:
      let defaultIdx = param.len - 1
      let typeIdx = param.len - 2
      let ptype = paramType(param)
      for i in 0 ..< typeIdx:
        result.add(
          {
            "name": param[i],
            "nameStr": newStrLitNode(param[i].strVal),
            "type": ptype,
            "defaultVal": param[defaultIdx]
          }.toTable
        )
