import macros, json, strutils

when not defined(js):
  import current/router

  macro rpc*(body: untyped): untyped =
    result = rpcServer(body)

  export json, parseEnum
else:
  import jsffi
  import current/client

  macro rpc*(body: untyped): untyped =
    result = rpcClient(body)

  export json, jsffi
