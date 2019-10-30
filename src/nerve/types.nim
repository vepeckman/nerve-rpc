import json
import promises

type RpcServiceKind* = enum rskClient, rskServer

type RpcServiceInst* = object of RootObj
  uri*: string
  kind*: RpcServiceKind
  nerveStrRpcRouter*: proc (request: string): Future[JsonNode]
  nerveJsonRpcRouter*: proc (request: JsonNode): Future[JsonNode]

type RpcService* = distinct string
proc `$`*(s: RpcService): string {.borrow.}

type ServiceConfigKind* = enum sckServer, sckClient, sckFull

type NerveDriver* = proc (req: JsonNode): Future[JsonNode] {.gcsafe.}
