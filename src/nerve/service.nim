import macros, macrocache
import common

const serviceMap = CacheTable("serviceMap")

proc checkParams(formalParams: NimNode) =
  # Ensure return types are future
  assert(formalParams[0].len > 1, "RPC procs need to return a future")
  assert(formalParams[0][0].strVal == "Future", "RPC procs need to return a future")

proc procDefs(node: NimNode): seq[NimNode] =
  # Gets all the proc definitions from the statement list
  for child in node:
    if child.kind == nnkProcDef:
      child.findChild(it.kind == nnkFormalParams).checkParams()
      result.add(child)

proc addService(name: string, procs: seq[NimNode]) =
  var procList = newStmtList()
  for p in procs:
    procList.add(p)
  serviceMap[name] = procList

proc getService*(name: string): NimNode = serviceMap[name]

macro service*(name: untyped, uri: static[string], body: untyped): untyped =
  let procs = procDefs(body)
  let nameStr = name.strVal()
  addService(nameStr, procs)
  result = newStmtList()
  result.add(rpcServiceType(nameStr, procs))
  result.add(rpcUriConst(nameStr, uri))
  echo repr result

