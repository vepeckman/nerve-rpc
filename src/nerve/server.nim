import macros, tables, strutils
import common

proc procDefs(node: NimNode): seq[NimNode] =
  # Gets all the proc definitions from the statement list
  for child in node:
    if child.kind == nnkProcDef:
      result.add(child)

proc dispatchName*(node: NimNode): NimNode = ident(dispatchPrefix & node.name.strVal.capitalizeAscii)

proc enumDeclaration*(enumName: NimNode, procs: seq[NimNode]): NimNode =
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

proc unboxExpression*(param: Table[string, NimNode], requestSym: NimNode): NimNode =
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

proc procWrapper*(requestSym, p: NimNode): NimNode =
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

proc dispatch*(procs: seq[NimNode], methodSym, requestSym: NimNode): NimNode =
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

