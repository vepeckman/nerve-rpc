import macros
import nerve/service, nerve/types, nerve/common, nerve/utils
when defined(js):
  import jsffi
else:
  import json

macro service*(name: untyped, uri: untyped = nil, body: untyped = nil): untyped =
  if body.kind != nnkNilLit:
    result = rpcService(name, uri.strVal(), body)
  else:
    result = rpcService(name, "", uri)

macro newServer*(rpc: static[RpcService]): untyped =
  let rpcName = $rpc
  let serverFactoryProc = rpcServerFactoryProc(rpcName)
  result = quote do:
    `serverFactoryProc`()

macro newClient*(rpc: static[RpcService], driver: NerveDriver): untyped =
  let clientFactoryProc = rpcClientFactoryProc($rpc)
  result = quote do:
    `clientFactoryProc`(`driver`)

macro rpcUri*(rpc: static[RpcService]): untyped =
  let rpcName = $rpc
  let uriConst = rpcName.rpcUriConstName
  result = quote do:
    `uriConst`

macro rpcType*(rpc: static[RpcService]): untyped =
  let typeName = rpcServiceName($rpc)
  result = quote do:
    `typeName`

macro routeRpc*(rpc: static[RpcService], server: RpcServiceInst, req: WObject): untyped =
  let rpcName = $rpc
  let routerProc = rpcName.rpcRouterProcName
  result = quote do:
    `routerProc`(`server`, `req`)

macro routeRpc*(rpc: static[RpcService], server: RpcServiceInst, req: string): untyped =
  let rpcName = $rpc
  let routerProc = rpcName.rpcRouterProcName
  result = quote do:
    `routerProc`(`server`, `req`)

export types
