import macros, tables, sequtils
import types, common, server, client, factories


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

proc procDefs(node: NimNode): seq[NimNode] =
  # Gets all the proc definitions from the statement list
  for child in node:
    if child.kind == nnkProcDef:
      child.findChild(it.kind == nnkFormalParams).checkParams()
      result.add(child)

proc serviceImports(): NimNode =
  result = quote do:
    import nerve/promises
    import nerve/web
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
  let injections = serverInjection(body)
  let serviceType = rpcServiceName(nameStr)
  result = newStmtList()
  result.add(serviceImports())
  if not defined(js):
    result.add(procs.mapIt(localProc(it, injections)).toStmtList())
  result.add(networkProcs(procs))
  result.add(rpcServiceType(nameStr, procs))
  result.add(rpcUriConst(nameStr, uri))
  if not defined(js):
    result.add(serverDispatch(nameStr, procs))
    result.add(rpcServerFactory(nameStr, serviceType, procs, injections))
  result.add(rpcClientFactory(nameStr, serviceType, procs))
  result.add(compiletimeReference(name))
  if defined(nerveRpcDebug):
    echo repr result
