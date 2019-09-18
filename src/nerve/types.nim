import promises, web

type RpcServiceKind* = enum rskClient, rskServer

type RpcServiceInst* = object of RootObj
  kind*: RpcServiceKind

type RpcService* = distinct string
proc `$`*(s: RpcService): string {.borrow.}

type ServiceConfigKind* = enum sckServer, sckClient, sckFull

type NerveDriver* = proc (req: JsonNode): Future[JsonNode] {.gcsafe.}
