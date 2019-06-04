import macros

when not defined(js):
  import json
  import current/server, current/runtime

  macro rpc*(name, uri, body: untyped): untyped =
    result = rpcServer(name, uri.strVal(), body)

  export json, runtime
else:
  import jsffi
  import current/client

  macro rpc*(name, uri, body: untyped): untyped =
    result = rpcClient(name, uri.strVal(), body)

  export jsffi

