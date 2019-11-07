import macros, json
import nerve/[service, types, common, promises, websockets, drivers, configure]

macro service*(name: untyped, uri: untyped = nil, body: untyped = nil): untyped =
  ## Macro to create a RpcService. The name param is the identifier used to reference
  ## the RpcService. The service can then be used in the other macros, including
  ## the server and client constructors. The uri is optional.
  if body.kind != nnkNilLit:
    result = rpcService(name, uri.strVal(), body)
  else:
    result = rpcService(name, "", uri)

macro inject*(injections: untyped): untyped =
  ## Modifier for the ``service`` macro. A list of variable declarations
  ## that will be injected into the RPC procs.
  assert(false, "inject may only be used inside a service definition")

macro serverImport*(imports: untyped): untyped =
  ## Modifier for the ``service`` macro. A list of modules to be imported
  ## when the service is built as a server.
  assert(false, "serverImport may only be used inside a service definition")

macro clientImport*(imports: untyped): untyped =
  ## Modifier for the ``service`` macro. A list of modules to be imported
  ## when the service is built as a client.
  assert(false, "clientImport may only be used inside a service definition")

macro server*(serverStmts: untyped): untyped =
  ## Modifier for the ``service`` macro. A code block to be executed when
  ## the service is built as a server.
  assert(false, "server may only be used inside a service definition")

macro client*(clientStmts: untyped): untyped =
  ## Modifier for the ``service`` macro. A code block to be executed when
  ## the service is built as a client.
  assert(false, "client may only be used inside a service definition")

macro newServer*(rpc: static[RpcService], injections: varargs[untyped]): untyped =
  ## Macro to construct a new server for a RpcService. Injections can be provided
  ## for the server, if defined by an ``inject`` statement in the service.
  let rpcName = $rpc
  let serverFactoryProc = rpcServerFactoryProc(rpcName)
  let factoryCall = quote do:
    `serverFactoryProc`()
  for injection in injections:
    factoryCall.add(injection)
  result = quote do:
    when not compiles(`factoryCall`):
      static:
        echo "Nerve Error: Call to " & `rpcName` & ".newServer doesn't include the proper injections"
        echo "             Error in Nerve's generated server function printed below"
    `factoryCall`

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

proc routeRpc*(server: RpcServiceInst, req: string | JsonNode): Future[JsonNode] =
  ## Dispatch a rpc request for the provided rpc service, returns a rpc response
  when $typeof(req) == "string":
    server.nerveStrRpcRouter(req)
  else:
    server.nerveJsonRpcRouter(req)

macro routeRpc*(rpc: static[RpcService], server: untyped, req: string | JsonNode): untyped =
  ## Macro to do the server side dispatch of the RPC request
  let rpcName = $rpc
  let routerProc = rpcName.rpcRouterProcName
  result = quote do:
    `routerProc`(`server`, `req`)

macro configureNerve*(config: untyped) =
  ## Macro to configure which services should generate server code or client code.
  ## Takes a map of RPC Services to ServiceConfigKind.
  mergeConfigObject(config)

macro setDefaultConfig*(config: static[ServiceConfigKind]) =
  ## Set the default configuration for RPC Services.
  setDefaultConfig(config)

export types, drivers
