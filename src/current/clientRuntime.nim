import jsffi

type
  InvalidResponseError = ref object of CatchableError
  RpcError = ref object of CatchableError

proc Boolean(o: JsObject): bool {. importc .}

proc respJson*(data: JsObject): JsObject {. importcpp: "#.json()" .}

proc respToJson*(resp: JsObject): JsObject =
  if Boolean(resp.ok):
    return respJson(resp)
  let msg = "Invalid Response: Server responsed with code " & $to(resp.status, int)
  raise InvalidResponseError(msg: msg)

proc handleRpcResponse*[T](rpcResponse: JsObject): T =
  let error = rpcResponse["error"]
  if Boolean(error):
    let msg = $error.message.to(cstring) & ": " & $error.data.msg.to(cstring) & "\n" & $error.data.stackTrace.to(cstring) & "\n"
    raise RpcError(msg: msg)
  rpcResponse["result"].to(T)

var JSON* {. importc, nodecl .}: JsObject
