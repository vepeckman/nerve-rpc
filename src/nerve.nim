import macros
import nerve/service, nerve/types, nerve/common, nerve/web, nerve/websockets, nerve/drivers, nerve/configure

macro service*(name: untyped, uri: untyped = nil, body: untyped = nil): untyped =
  ## Macro to create a RpcService. The name param is the identifier used to reference
  ## the RpcService. The service can then be used in the other macros, including
  ## the server and client constructors. The uri is optional.
  if body.kind != nnkNilLit:
    result = rpcService(name, uri.strVal(), body)
  else:
    result = rpcService(name, "", uri)

macro newServer*(rpc: static[RpcService], injections: varargs[untyped]): untyped =
  ## Macro to construct a new server for a RpcService. Injections can be provided
  ## for the server, if defined by an ``inject`` statement in the service.
  let rpcName = $rpc
  let serverFactoryProc = rpcServerFactoryProc(rpcName)
  result = quote do:
    `serverFactoryProc`()
  for injection in injections:
    result.add(injection)

macro newClient*(rpc: static[RpcService], driver: NerveDriver): untyped =
  ## Macro for constructing a new client for a RpcService. A driver can be
  ## found in the ``drivers`` module or user defined.
  let clientFactoryProc = rpcClientFactoryProc($rpc)
  result = quote do:
    `clientFactoryProc`(`driver`)

macro newHttpClient*(rpc: static[RpcService], host: static[string] = ""): untyped =
  ## Macro to create a new client loaded with the http driver. The macro uses
  ## the provided service uri, prefixed with an optional host.
  let clientFactoryProc = rpcClientFactoryProc($rpc)
  let serviceName = ident($rpc)
  result = quote do:
    `clientFactoryProc`(newHttpDriver(`host` & `serviceName`.rpcUri))

macro newWsClient*(rpc: static[RpcService], webSocket: WebSocket): untyped =
  ## Macro to create a new client loaded with the websocket driver. The macro uses
  ## the provided websocket which the user is responsible for initializing.
  let clientFactoryProc = rpcClientFactoryProc($rpc)
  let serviceName = ident($rpc)
  result = quote do:
    `clientFactoryProc`(newWsDriver(`websocket`))

macro rpcUri*(rpc: static[RpcService]): untyped =
  ## Macro that provides a compile time reference to the 
  ## provided service uri. Useful in ``case`` statements.
  let rpcName = $rpc
  let uriConst = rpcName.rpcUriConstName
  result = quote do:
    `uriConst`

macro rpcType*(rpc: static[RpcService]): untyped =
  ## Macro to provide reference to the generated
  ## RpcServiceInst subtype. This type describes the objects
  ## returned by ``newClient`` and ``newServer``
  let typeName = rpcServiceName($rpc)
  result = quote do:
    `typeName`

macro routeRpc*(rpc: static[RpcService], server: RpcServiceInst, req: JsonNode): untyped =
  ## Macro to do the server side dispatch of the RPC request
  let rpcName = $rpc
  let routerProc = rpcName.rpcRouterProcName
  result = quote do:
    `routerProc`(`server`, `req`)

macro routeRpc*(rpc: static[RpcService], server: RpcServiceInst, req: string): untyped =
  ## Macro to do the server side dispatch of the RPC request
  let rpcName = $rpc
  let routerProc = rpcName.rpcRouterProcName
  result = quote do:
    `routerProc`(`server`, `req`)

macro configureNerve*(config: untyped) =
  ## Macro to configure which services should generate server code or client code
  mergeConfigObject(config)

export types, drivers
