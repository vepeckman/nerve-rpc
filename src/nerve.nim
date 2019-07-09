import macros
import nerve/service, nerve/types, nerve/common
when defined(js):
  import jsffi
else:
  import json

macro service*(name: untyped, uri: static[string], body: untyped): untyped =
  result = rpcService(name, uri, body)

macro rpcUri*(rpc: RpcService): untyped =
  let rpcName = rpc.strVal()
  let uriConst = rpcName.rpcUriConstName
  result = quote do:
    `uriConst`

macro routeRpc*(rpc: RpcService, req: JsonNode): untyped =
  let rpcName = rpc.strVal()
  let routerProc = rpcName.rpcRouterProcName
  result = quote do:
    `routerProc`(`req`)

macro routeRpc*(rpc: RpcService, req: string): untyped =
  let rpcName = rpc.strVal()
  let routerProc = rpcName.rpcRouterProcName
  result = quote do:
    `routerProc`(`req`)

export types
