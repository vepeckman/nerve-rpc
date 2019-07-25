import macros, tables
import common, types

proc createServerProc(p: NimNode, name: string, injections: seq[Table[string, NimNode]]): NimNode =
  let providedProcName = p[0].basename
  let procCall = nnkCall.newTree(providedProcName)
  let params = p.findChild(it.kind == nnkFormalParams).getParams()
  for param in params:
    procCall.add(param["name"])
  for injection in injections:
    procCall.add(injection["ident"])
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

proc rpcServerFactory*(name: string, serviceType: NimNode, procs: seq[NimNode], injections: seq[Table[string, NimNode]]): NimNode =
  let procName = rpcServerFactoryProc(name)
  var serverProcs = newStmtList()
  var procTable = initTable[string, NimNode]()
  for p in procs:
    let serverProcName ="NerveServer" & p[0].basename.strVal()
    procTable[serverProcName] = p
    serverProcs.add(createServerProc(p, serverProcName, injections))
  let service = rpcServiceObject(name, procTable, rskServer)
  result = quote do:
    proc `procName`*(): `serviceType` =
      `serverProcs`
      `service`
  let params = result.findChild(it.kind == nnkFormalParams)
  for injection in injections:
    params.add(nnkIdentDefs.newTree(
      injection["ident"],
      injection["type"],
      injection["default"]
    ))


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
  let service = rpcServiceObject(name, procTable, rskClient)
  result = quote do:
    proc `procName`*(`driverName`: NerveDriver): `serviceType` =
      `clientProcs`
      `service`
