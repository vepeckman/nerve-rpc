import macros, tables, sequtils, options
import types, common, configure, server, client, factories

proc checkParams(formalParams: NimNode) =
  # Ensure return types are future
  assert(formalParams[0].len > 1, "RPC procs need to return a future")
  assert(formalParams[0][0].strVal == "Future", "RPC procs need to return a future")

proc toStmtList(nodes: seq[NimNode]): NimNode =
  result = newStmtList()
  for node in nodes:
    result.add(node)

proc serverInjection(node: NimNode): seq[Table[string, NimNode]] =
  let injectStmt = node.findChild(it.kind == nnkCall and it[0] == ident("inject") and it[1].kind == nnkStmtList)
  if injectStmt.kind != nnkNilLit:
    for child in injectStmt[1]:
      if child.kind == nnkVarSection:
        for declaration in child:
          result.add({
            "ident": declaration[0],
            "type": paramType(declaration),
            "default": declaration[2]
          }.toTable)

proc serviceImports(node: NimNode, id: string): Option[NimNode] =
  result = none(NimNode)
  let importStmt = node.findChild(it.kind == nnkCall and it[0] == ident(id))
  if importStmt.kind != nnkNilLit:
    var generatedImports = nnkImportStmt.newTree()
    for idx in 1 ..< importStmt.len:
      generatedImports.add(importStmt[idx])
    result = some(generatedImports)

proc serviceSetup(node: NimNode, id: string): Option[NimNode] =
  result = none(NimNode)
  let setupStmt = node.findChild(it.kind == nnkCall and it[0] == ident(id) and it[1].kind == nnkStmtList)
  if setupStmt.kind != nnkNilLit:
    result = some(setupStmt[1])

proc procDefs(node: NimNode): seq[NimNode] =
  # Gets all the proc definitions from the statement list
  for child in node:
    if child.kind == nnkProcDef:
      child.findChild(it.kind == nnkFormalParams).checkParams()
      result.add(child)

proc nerveImports(): NimNode =
  result = quote do:
    import json
    import nerve/promises
    import nerve/types
    import nerve/serverRuntime
    import nerve/clientRuntime

proc compiletimeReference(name: NimNode): NimNode =
  let nameStr = name.strVal().newStrLitNode()
  result = quote do:
    const `name`* = RpcService(`nameStr`)

proc rpcService*(name: NimNode, uri: string, body: NimNode): NimNode =
  let procs = procDefs(body)
  let nameStr = name.strVal()
  let serviceType = rpcServiceName(nameStr)

  let config = getConfig(nameStr)
  let isServer = config in [sckServer, sckFull]
  let isClient = config in [sckClient, sckFull]

  let injections = serverInjection(body)
  let serverImports = serviceImports(body, "serverImports")
  let clientImports = serviceImports(body, "clientImports")
  let serverSetup = serviceSetup(body, "server")
  let clientSetup = serviceSetup(body, "client")

  result = newStmtList()
  result.add(nerveImports())
  if isServer:
    result.add(if serverImports.isSome: serverImports.get() else: newEmptyNode())
    result.add(procs.mapIt(localProc(it, injections)).toStmtList())
  if isClient:
    result.add(if clientImports.isSome: clientImports.get() else: newEmptyNode())
    result.add(networkProcs(procs, uri))
  result.add(rpcServiceType(nameStr, procs))
  result.add(rpcUriConst(nameStr, uri))
  if isServer:
    result.add(serverDispatch(nameStr, procs))
    result.add(rpcServerFactory(nameStr, serviceType, uri, procs, injections))
  if isClient:
    result.add(rpcClientFactory(nameStr, serviceType, uri, procs))
  result.add(compiletimeReference(name))
  if isServer and serverSetup.isSome:
    result.add(serverSetup.get())
  if isClient and clientSetup.isSome:
    result.add(clientSetup.get())
  if defined(nerveRpcDebug):
    echo repr result
