import macros, tables
import common

proc checkParams(formalParams: NimNode) =
  # Ensure return types are future
  assert(formalParams[0].len > 1, "RPC procs need to return a future")
  assert(formalParams[0][0].strVal == "Future", "RPC procs need to return a future")

proc toStmtList(nodes: seq[NimNode]): NimNode =
  result = newStmtList()
  for node in nodes:
    result.add(node)

proc procDefs(node: NimNode): seq[NimNode] =
  # Gets all the proc definitions from the statement list
  for child in node:
    if child.kind == nnkProcDef:
      child.findChild(it.kind == nnkFormalParams).checkParams()
      result.add(child)

proc rpcServiceObj*(name: string, procs: Table[string, NimNode], uri = "rpc"): NimNode =
  let typeName = rpcServiceName(name)
  result = quote do:
    `typeName`(uri: `uri`)
  for pName in procs.keys:
    var field = newColonExpr(procs[pName][0].basename, ident(pName))
    result.add(field)


proc paramType(param: NimNode): NimNode =
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

proc getParams(formalParams: NimNode): seq[Table[string, NimNode]] =
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

proc networkProcName(name: string): NimNode = ident("NerveNetwork" & name)

proc createServerProc(p: NimNode, name: string): NimNode =
  let providedProcName = p[0].basename
  let procCall = nnkCall.newTree(providedProcName)
  let params = p.findChild(it.kind == nnkFormalParams).getParams()
  for param in params:
    procCall.add(param["name"])
  result = copy(p)
  result[result.len - 1] = procCall
  result[0] = ident(name)

proc createClientProc(p: NimNode, name, networkProc: string): NimNode =
  let procCall = nnkCall.newTree(networkProcName(networkProc))
  let params = p.findChild(it.kind == nnkFormalParams).getParams()
  for param in params:
    procCall.add(param["name"])
  result = copy(p)
  result[result.len - 1] = procCall
  result[0] = ident(name)

proc rpcServerFactory(name: string, serviceType: NimNode, procs: seq[NimNode]): NimNode =
  let procName = ident("NerveRpc" & name & "ServerFactory")
  var serverProcs = newStmtList()
  var procTable = initTable[string, NimNode]()
  for p in procs:
    let serverProcName ="NerveServer" & p[0].basename.strVal()
    procTable[serverProcName] = p
    serverProcs.add(createServerProc(p, serverProcName))
  let service = rpcServiceObj(name, procTable)
  result = quote do:
    proc `procName`(): `serviceType` =
      `serverProcs`
      `service`

proc rpcClientFactory(name: string, serviceType: NimNode, procs: seq[NimNode]): NimNode =
  let procName = ident("NerveRpc" & name & "ClientFactory")
  var clientProcs = newStmtList()
  var procTable = initTable[string, NimNode]()
  for p in procs:
    let pName = p[0].basename.strVal()
    let clientProcName ="NerveClient" & pName
    procTable[clientProcName] = p
    clientProcs.add(createClientProc(p, clientProcName, pName))
  let service = rpcServiceObj(name, procTable)
  result = quote do:
    proc `procName`(): `serviceType` =
      `clientProcs`
      `service`

proc networkProcBody(p: NimNode): NimNode =
  let nameStr = newStrLitNode(p.name.strVal)
  let formalParams = p.findChild(it.kind == nnkFormalParams)
  let retType = formalParams[0][1]
  let params = formalParams.getParams()
  let req = genSym()
  let newJsObject = if defined(js): ident("newJsObject") else: ident("newJObject")

  var paramJson = nnkStmtList.newTree()
  for param in params:
    let nameStr = param["nameStr"]
    let name = param["name"]
    paramJson.add(
      quote do:
        `req`["params"][`nameStr`] = % `name`
    )
  
  result = quote do:
    let `req` = `newJsObject`()
    `req`["jsonrpc"] = % "2.0"
    `req`["id"] = % 0
    `req`["method"] = % `nameStr`
    `req`["params"] = `newJsObject`()
    `paramJson`
    result = newFuture[`retType`]()
    result.complete(`req`.to(`retType`))

proc rpcNetworkProcs(procs: seq[NimNode]): NimNode =
  result = newStmtList()
  for p in procs:
    let networkProc = copy(p)
    networkProc[0] = networkProcName(p[0].basename.strVal())
    networkProc[networkProc.len - 1] = networkProcBody(networkProc)
    result.add(networkProc)

macro service*(name: untyped, uri: static[string], body: untyped): untyped =
  let procs = procDefs(body)
  let nameStr = name.strVal()
  let serviceType = rpcServiceName(nameStr)
  result = newStmtList()
  result.add(procs.toStmtList())
  result.add(rpcNetworkProcs(procs))
  result.add(rpcServiceType(nameStr, procs))
  result.add(rpcUriConst(nameStr, uri))
  result.add(rpcServerFactory(nameStr, serviceType, procs))
  result.add(rpcClientFactory(nameStr, serviceType, procs))
  echo repr result

import json
export json
