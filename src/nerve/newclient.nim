import macros, tables
import common, service, drivers

proc procDefs(node: NimNode): seq[NimNode] =
  # Gets all the proc definitions from the statement list
  for child in node:
    if child.kind == nnkProcDef:
      result.add(child)

proc getParams(formalParams: NimNode): seq[Table[string, NimNode]] =
  # Find all the parameters and build a table with needed information
  assert(formalParams[0].len > 1, "RPC procs need to return a future")
  assert(formalParams[0][0].strVal == "Future", "RPC procs need to return a future")
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

proc procBody(p, driver: NimNode): NimNode =
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
    result = `driver`[`retType`](`req`)

macro client*(service: untyped, driver: NerveDriver): untyped =
  result = newStmtList()
  let name = service.strVal()
  let uri = ""
  let body = getService(name)
  let procs = procDefs(body)
  for p in procs:
    let newBody = procBody(p, driver)
    p[p.len - 1] = newBody
    result.add(p)
  result.add(rpcServiceObject(name, procs, uri))
  echo repr result

import json
export json
