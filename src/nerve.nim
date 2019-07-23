import macros
import nerve/service, nerve/types, nerve/common, nerve/web, nerve/drivers

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

macro newHttpClient*(rpc: static[RpcService], host: static[string] = ""): untyped =
  let clientFactoryProc = rpcClientFactoryProc($rpc)
  let serviceName = ident($rpc)
  result = quote do:
    `clientFactoryProc`(newHttpDriver(`host` & `serviceName`.rpcUri))

macro rpcUri*(rpc: static[RpcService]): untyped =
  let rpcName = $rpc
  let uriConst = rpcName.rpcUriConstName
  result = quote do:
    `uriConst`

macro rpcType*(rpc: static[RpcService]): untyped =
  let typeName = rpcServiceName($rpc)
  result = quote do:
    `typeName`

macro routeRpc*(rpc: static[RpcService], server: RpcServiceInst, req: JsObject): untyped =
  let rpcName = $rpc
  let routerProc = rpcName.rpcRouterProcName
  result = quote do:
    `routerProc`(`server`, `req`)

macro routeRpc*(rpc: static[RpcService], server: RpcServiceInst, req: string): untyped =
  let rpcName = $rpc
  let routerProc = rpcName.rpcRouterProcName
  result = quote do:
    `routerProc`(`server`, `req`)

export types, drivers
