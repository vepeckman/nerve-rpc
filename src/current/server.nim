import macros, tables, asyncdispatch
import common

proc procDefs(node: NimNode): seq[NimNode] =
  # Gets all the proc definitions from the statement list
  for child in node:
    if child.kind == nnkProcDef:
      result.add(child)

const dispatchPrefix = "nerveRpc"
proc dispatchName(node: NimNode): NimNode = ident(dispatchPrefix & node.name.strVal)

proc enumDeclaration(enumName: NimNode, procs: seq[NimNode]): NimNode =
  # The enum used to dispatch methods
  var enumTy = nnkEnumTy.newTree(newEmptyNode())
  for p in procs:
    enumTy.add(dispatchName(p))
  result = quote do:
    type `enumName` = `enumTy`

proc paramType(param: NimNode): NimNode =
  # Either returns the type node of the param
  # or creates a node that gets the type of default value
  let defaultIdx = param.len - 1
  let typeIdx = param.len - 2
  if param[typeIdx].kind == nnkEmpty:
    var defaultParam = param[defaultIdx]
    result = quote do:
      type(`defaultParam`)
  else:
    result = param[typeIdx]

proc getParams(formalParams: NimNode): seq[Table[string, NimNode]] =
  # Find all the parameters and build a table with needed information
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

proc unboxParam(param: Table[string, NimNode], requestSym: NimNode): NimNode =
  # Retrieve the param from the request, convert to Nim type
  result = nnkStmtList.newTree()
  var nameStr = param["nameStr"]
  var ntype = param["type"]
  var defaultVal = param["defaultVal"]

  if defaultVal.kind != nnkEmpty:
    result.add(quote do:
      if `requestSym`["params"].hasKey(`nameStr`):
        `requestSym`["params"][`nameStr`].to(`ntype`)
      else: `defaultVal`
    )
  else:
    result.add(quote do:
      `requestSym`["params"][`nameStr`].to(`ntype`)
    )

proc procWrapper(requestSym, responseSym, p: NimNode): NimNode =
  # This wrapper gets the parameters from the request and uses them to invoke the proc
  result = nnkStmtList.newTree()
  var methodCall = nnkCall.newTree(p.name)
  let params = p.findChild(it.kind == nnkFormalParams).getParams()

  for param in params:
    var name = param["name"]
    let unboxExpression = param.unboxParam(requestSym)
    result.add(quote do:
      let `name` = `unboxExpression`
    )
    methodCall.add(name)

  # Invoke the method with the params, convert to json, and return response
  result.add(quote do:
      `responseSym` = % await `methodCall`
  )

proc dispatch(procs: seq[NimNode], methodSym, requestSym, responseSym: NimNode): NimNode =
  # Create the case statement used to dispatch proc
  result = nnkCaseStmt.newTree(methodSym)

  for p in procs:
    # Add the branch that dispatches the proc
    let wrapper = procWrapper(requestSym, responseSym, p)
    result.add(
      nnkOfBranch.newTree(
        dispatchName(p),
        wrapper
    ))

proc rpcServer*(name: NimNode, uri: string, body: NimNode): NimNode =
  let 
    enumSym = genSym(nskType) # Type name the enum used to dispatch procs
    methodSym = genSym(nskLet) # Variable that holds the requested method
    requestSym = ident("request") # The request parameter
    responseSym = ident("response") # The response return value
    routerSym = rpcRouterProcName(name)
  let procs = procDefs(body)

  let dispatchStatement = dispatch(procs, methodSym, requestSym, responseSym)
  let enumDeclaration = enumDeclaration(enumSym, procs)

  body.add(rpcServiceType(name, procs))
  body.add(rpcServiceObject(name, procs, uri))
  body.add(rpcUriConst(name, uri))

  body.add(quote do:
    `enumDeclaration`
    proc `routerSym`*(`requestSym`: JsonNode): Future[JsonNode] {.async.} =
      var `responseSym`: JsonNode
      let `methodSym` = parseEnum[`enumSym`](`dispatchPrefix` & `requestSym`["method"].getStr())
      `dispatchStatement`
      result = `responseSym`
  )
  result = body

  if defined(nerveRpcDebug):
    echo repr result
