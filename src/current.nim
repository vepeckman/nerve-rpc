import macros, json, strutils
import current/router

macro rpc*(body: untyped): untyped =
  result = rpcServer(body)

export json, parseEnum
