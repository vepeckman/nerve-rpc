import macros, tables, strutils
import common

proc dispatchName(node: NimNode): NimNode = ident(dispatchPrefix & node.name.strVal.capitalizeAscii)

proc enumDeclaration(enumName: NimNode, procs: seq[NimNode]): NimNode =
  # The enum used to dispatch methods
  var enumTy = nnkEnumTy.newTree(newEmptyNode())
  for p in procs:
    enumTy.add(dispatchName(p))
  result = quote do:
    type `enumName` = `enumTy`

proc unboxExpression(param: Table[string, NimNode], requestSym: NimNode): NimNode =
  # Retrieve the param from the request, convert to Nim type
  var nameStr = param["nameStr"]
  var ntype = param["type"]
  var defaultVal = param["defaultVal"]

  if defaultVal.kind != nnkEmpty:
    result = quote do:
      nerveUnboxParameter(`requestSym`, `nameStr`, `defaultVal`)
  else:
    result = quote do:
      nerveUnboxParameter[`ntype`](`requestSym`, `nameStr`)

proc procWrapper(requestSym, p: NimNode): NimNode =
  # This wrapper gets the parameters from the request and uses them to invoke the proc
  result = nnkStmtList.newTree()
  var methodCall = nnkCall.newTree(p.name)
  let params = p.findChild(it.kind == nnkFormalParams).getParams()

  for param in params:
    var name = param["name"]
    let unboxExpr = param.unboxExpression(requestSym)
    result.add(quote do:
      let `name` = `unboxExpr`
    )
    methodCall.add(name)

  # Invoke the method with the params, convert to json, and return response
  result.add(quote do:
      result["result"] = % await `methodCall`
  )

proc dispatch(procs: seq[NimNode], methodSym, requestSym: NimNode): NimNode =
  # Create the case statement used to dispatch proc
  result = nnkCaseStmt.newTree(methodSym)

  for p in procs:
    # Add the branch that dispatches the proc
    let wrapper = procWrapper(requestSym, p)
    result.add(
      nnkOfBranch.newTree(
        dispatchName(p),
        wrapper
    ))

proc serverDispatch*(name: string, procs: seq[NimNode]): NimNode =
  let uri = ""

  let 
    enumSym = genSym(nskType) # Type name the enum used to dispatch procs
    methodSym = genSym(nskLet) # Variable that holds the requested method
    serverSym = ident("server")
    serviceType = rpcServiceName(name)
    requestSym = ident("request") # The request parameter
    routerSym = rpcRouterProcName(name)
    routerName = routerSym.strVal()

  let dispatchStatement = dispatch(procs, methodSym, requestSym)
  let enumDeclaration = enumDeclaration(enumSym, procs)

  result = newStmtList()

  result.add(quote do:
    `enumDeclaration`
    proc `routerSym`*(`serverSym`: `serviceType`,`requestSym`: JsObject): Future[JsObject] {.async.} =
      assert(`serverSym`.kind == rskServer, "Only Nerve Servers can do routing")
      result = newNerveResponse()
      if not nerveValidateRequest(`requestSym`):
        result["id"] = if `requestSym`.hasKey("id"): `requestSym`["id"] else: newJNull()
        result["error"] = newNerveError(-32600, "Invalid Request")
      try:
        let `methodSym` = nerveGetMethod[`enumSym`](`requestSym`)
        `dispatchStatement`
      except DispatchError as e:
        result["error"] = newNerveError(-32601, "Method not found", e)
      except ParameterError as e:
        result["error"] = newNerveError(-32602, "Invalid params", e)
      except CatchableError as e:
        result["error"] = newNerveError(-32000, "Server error", e)

    proc `routerSym`*(`serverSym`: `serviceType`,`requestSym`: string): Future[JsObject] =
      assert(`serverSym`.kind == rskServer, "Only Nerve Servers can do routing")
      try:
        let requestJson = parseJson(`requestSym`)
        result = `routerSym`(`serverSym`, requestJson)
      except CatchableError as e:
        result = newFuture[JsObject](`routerName`)
        var response = newNerveResponse()
        response["error"] = newNerveError(-32700, "Parse error", e)
        result.complete(response)
  )
