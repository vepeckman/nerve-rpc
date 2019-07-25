import macros, tables
import common

proc networkProcBody(p: NimNode, methodName: string): NimNode =
  let formalParams = p.findChild(it.kind == nnkFormalParams)
  let retType = formalParams[0][1]
  let params = formalParams.getParams()
  let req = genSym()
  let driver = ident("nerveDriver")

  var paramJson = nnkStmtList.newTree()
  for param in params:
    let nameStr = param["nameStr"]
    let name = param["name"]
    paramJson.add(
      quote do:
        `req`["params"][`nameStr`] = toJs `name`
    )
  
  result = quote do:
    let `req` = newJsObject()
    `req`["jsonrpc"] = toJs "2.0"
    `req`["id"] = toJs 0
    `req`["method"] = toJs `methodName`
    `req`["params"] = newJsObject()
    `paramJson`
    result = `driver`(`req`)
      .then(handleRpcResponse[`retType`])

proc networkProcs*(procs: seq[NimNode]): NimNode =
  result = newStmtList()
  for p in procs:
    let networkProc = copy(p)
    let methodName = p[0].basename.strVal()
    networkProc[0] = networkProcName(methodName)
    networkProc[networkProc.len - 1] = networkProcBody(networkProc, methodName)
    networkProc.findChild(it.kind == nnkFormalParams).add(
      nnkIdentDefs.newTree(
        ident("nerveDriver"),
        ident("NerveDriver"),
        newEmptyNode()
      )
    )
    result.add(networkProc)
