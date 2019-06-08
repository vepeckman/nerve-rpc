import macros

when not defined(js):
  import json
  import current/server, current/serverRuntime

  macro rpc*(name, uri, body: untyped): untyped =
    result = rpcServer(name, uri.strVal(), body)

  export json, serverRuntime
else:
  import jsffi
  import current/client, current/clientRuntime

  macro rpc*(name, uri, body: untyped): untyped =
    result = rpcClient(name, uri.strVal(), body)

  export jsffi, clientRuntime

