import macros

when not defined(js):
  import json, strutils
  import current/server

  macro rpc*(name, uri, body: untyped): untyped =
    result = rpcServer(name, uri.strVal(), body)

  export json, parseEnum
else:
  import jsffi
  import current/client

  macro rpc*(name, uri, body: untyped): untyped =
    result = rpcClient(name, uri.strVal(), body)

  export jsffi

