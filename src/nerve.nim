import macros

when not defined(js):
  import json
  import nerve/server, nerve/serverRuntime

  macro rpc*(name, uri, body: untyped): untyped =
    result = rpcServer(name, uri.strVal(), body)

  export json, serverRuntime
else:
  import jsffi
  import nerve/client, nerve/clientRuntime

  macro rpc*(name, uri, body: untyped): untyped =
    result = rpcClient(name, uri.strVal(), body)

  export jsffi, clientRuntime

