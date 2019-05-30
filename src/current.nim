import macros, json, strutils
import current/common

when not defined(js):
  import current/router

  macro rpc*(name, uri, body: untyped): untyped =
    result = rpcServer(name, uri.strVal(), body)

  export json, parseEnum
else:
  import jsffi
  import current/client

  macro rpc*(name, uri, body: untyped): untyped =
    result = rpcClient(name, uri.strVal(), body)

  export json, jsffi

export common
