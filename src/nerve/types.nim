import promises, web

type RpcServiceKind* = enum rskClient, rskServer

type RpcServiceInst* = object of RootObj
  uri*: string
  kind*: RpcServiceKind
  nerveStrRpcRouter*: proc (request: string): Future[JsonNode]
  nerveJsonRpcRouter*: proc (request: JsonNode): Future[JsonNode]

# TODO: Move to main file
proc routeRpc*(server: RpcServiceInst, req: string | JsonNode): Future[JsonNode] =
  when $typeof(req) == "string":
    server.nerveStrRpcRouter(req)
  else:
    server.nerveJsonRpcRouter(req)

type RpcService* = distinct string
proc `$`*(s: RpcService): string {.borrow.}

type ServiceConfigKind* = enum sckServer, sckClient, sckFull

type NerveDriver* = proc (req: JsonNode): Future[JsonNode] {.gcsafe.}
