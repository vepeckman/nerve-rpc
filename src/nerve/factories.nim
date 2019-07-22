import macros, tables
import common

proc createServerProc(p: NimNode, name: string): NimNode =
  let providedProcName = p[0].basename
  let procCall = nnkCall.newTree(providedProcName)
  let params = p.findChild(it.kind == nnkFormalParams).getParams()
  for param in params:
    procCall.add(param["name"])
  result = copy(p)
  result[result.len - 1] = procCall
  result[0] = ident(name)

proc createClientProc(p: NimNode, name, networkProc: string, driver: NimNode): NimNode =
  let procCall = nnkCall.newTree(networkProcName(networkProc))
  let params = p.findChild(it.kind == nnkFormalParams).getParams()
  for param in params:
    procCall.add(param["name"])
  procCall.add(driver)
  result = copy(p)
  result[result.len - 1] = procCall
  result[0] = ident(name)

proc rpcServerFactory*(name: string, serviceType: NimNode, procs: seq[NimNode]): NimNode =
  let procName = rpcServerFactoryProc(name)
  var serverProcs = newStmtList()
  var procTable = initTable[string, NimNode]()
  for p in procs:
    let serverProcName ="NerveServer" & p[0].basename.strVal()
    procTable[serverProcName] = p
    serverProcs.add(createServerProc(p, serverProcName))
  let service = rpcServiceObject(name, procTable)
  result = quote do:
    proc `procName`*(): `serviceType` =
      `serverProcs`
      `service`

proc rpcClientFactory*(name: string, serviceType: NimNode, procs: seq[NimNode]): NimNode =
  let procName = rpcClientFactoryProc(name)
  let driverName = ident("nerveDriver")
  var clientProcs = newStmtList()
  var procTable = initTable[string, NimNode]()
  for p in procs:
    let pName = p[0].basename.strVal()
    let clientProcName ="NerveClient" & pName
    procTable[clientProcName] = p
    clientProcs.add(createClientProc(p, clientProcName, pName, driverName))
  let service = rpcServiceObject(name, procTable)
  result = quote do:
    proc `procName`*(`driverName`: NerveDriver): `serviceType` =
      `clientProcs`
      `service`
