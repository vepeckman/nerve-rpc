import utils
when not defined(js):
  import asyncdispatch
else:
  import asyncjs

type RpcServiceKind* = enum rskClient, rskServer

type RpcServiceInst* = object of RootObj
  kind*: RpcServiceKind

type RpcService* = distinct string
proc `$`*(s: RpcService): string {.borrow.}

type NerveDriver* = proc (req: WObject): Future[WObject]
