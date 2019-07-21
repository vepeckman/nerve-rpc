import macros
import nerve/service, nerve/types, nerve/common, nerve/utils
when defined(js):
  import jsffi
else:
  import json

macro service*(name: untyped, uri: static[string], body: untyped): untyped =
  result = rpcService(name, uri, body)

macro newServer*(rpc: static[RpcServiceName]): untyped =
  let rpcName = $rpc
  let serverFactoryProc = rpcServerFactoryProc(rpcName)
  result = quote do:
    `serverFactoryProc`()

macro newClient*(rpc: static[RpcServiceName], driver: NerveDriver): untyped =
  let clientFactoryProc = rpcClientFactoryProc($rpc)
  result = quote do:
    `clientFactoryProc`(`driver`)

macro rpcUri*(rpc: static[RpcServiceName]): untyped =
  let rpcName = $rpc
  let uriConst = rpcName.rpcUriConstName
  result = quote do:
    `uriConst`

macro routeRpc*(rpc: static[RpcServiceName], server: RpcService, req: WObject): untyped =
  let rpcName = $rpc
  let routerProc = rpcName.rpcRouterProcName
  result = quote do:
    `routerProc`(`server`, `req`)

macro routeRpc*(rpc: static[RpcServiceName], server: RpcService, req: string): untyped =
  let rpcName = $rpc
  let routerProc = rpcName.rpcRouterProcName
  result = quote do:
    `routerProc`(`server`, `req`)

export types
