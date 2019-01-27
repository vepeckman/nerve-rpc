import macros, json, strutils
import webRPC/router

macro rpc*(body: untyped): untyped =
  result = rpcServer(body)

export json, parseEnum
