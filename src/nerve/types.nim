import utils
when not defined(js):
  import asyncdispatch
else:
  import asyncjs

type RpcService* = object of RootObj
  uri*: string

type RpcServiceName* = distinct string

type NerveDriver* = proc (req: WObject): Future[WObject]
