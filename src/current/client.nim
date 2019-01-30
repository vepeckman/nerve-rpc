import macros, jsffi, tables, future
import fetch

proc procDefs(node: NimNode): seq[NimNode] =
  # Gets all the proc definitions from the statement list
  for child in node:
    if child.kind == nnkProcDef:
      result.add(child)

proc getParams(formalParams: NimNode): seq[Table[string, NimNode]] =
  # Find all the parameters and build a table with needed information
  for param in formalParams:
    if param.kind == nnkIdentDefs:
      let defaultIdx = param.len - 1
      let typeIdx = param.len - 2
      for i in 0 ..< typeIdx:
        result.add(
          {
            "name": param[i],
            "nameStr": newStrLitNode(param[i].strVal),
          }.toTable
        )


proc procBody(p: NimNode): NimNode =
  let name = p.name
  let formalParams = p.findChild(it.kind == nnkFormalParams)
  let retType = formalParams[0][1]
  let params = formalParams.getParams()

  var paramJson = nnkTableConstr.newTree()
  for param in params:
    paramJson.add(nnkExprColonExpr.newTree(param["nameStr"], param["name"]))
  
  result = quote do:
    let req = newJsObject()
    req["method"] = cstring"POST"
    req["body"] = %* `paramJson`
    result = fetch(cstring("/rpc"), req)
      .then((resp: JsObject) => resp.json())
      .then((data: JsObject) => data.to(`retType`))

proc rpcClient*(body: NimNode): NimNode =
  result = newStmtList()
  let procs = procDefs(body)
  for p in procs:
    let newBody = procBody(p)
    p[p.len - 1] = newBody
    result.add(p)
