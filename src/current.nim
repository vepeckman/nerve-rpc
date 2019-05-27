import macros, json, strutils
import current/common

when not defined(js):
  import current/router

  macro rpc*(name, body: untyped): untyped =
    result = rpcServer(name, body)

  export json, parseEnum
else:
  import jsffi
  import current/client

  macro rpc*(name, body: untyped): untyped =
    result = rpcClient(body)

  export json, jsffi

export common
