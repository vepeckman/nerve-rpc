import promises, web

type RpcServiceKind* = enum rskClient, rskServer

type RpcServiceInst*[T] = object of RootObj
  uri*: string
  nerveStrRpcRouter*: proc (server: T, request: string): Future[JsonNode]
  nerveJsonRpcRouter*: proc (server: T, request: JsonNode): Future[JsonNode]
  kind*: RpcServiceKind

proc routeRpc*[T](server: T, req: string | JsonNode): Future[JsonNode] =
  when $typeof(req) == "string":
    when not compiles(server.nerveStrRpcRouter(server, req)):
      static:
        assert(false, "Type error: `routeRpc` must receive a Nerve RPC service")
    server.nerveStrRpcRouter(server, req)
  else:
    when not compiles(server.nerveJsonRpcRouter(server, req)):
      static:
        assert(false, "Type error: `routeRpc` must receive a Nerve RPC service")
    server.nerveJsonRpcRouter(server, req)

type RpcService* = distinct string
proc `$`*(s: RpcService): string {.borrow.}

type ServiceConfigKind* = enum sckServer, sckClient, sckFull

type NerveDriver* = proc (req: JsonNode): Future[JsonNode] {.gcsafe.}
