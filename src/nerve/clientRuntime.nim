import web

type
  InvalidResponseError* = ref object of CatchableError
  RpcError* = ref object of CatchableError


proc handleRpcResponse*[T](rpcResponse: JsObject): T =
  if hasKey(rpcResponse, "error"):
    let error = rpcResponse["error"]
    let msg = $error["message"].to(wstring) & ": " & $error["data"]["msg"].to(wstring) & "\n" & $error["data"]["stackTrace"].to(wstring) & "\n"
    raise RpcError(msg: msg)
  rpcResponse["result"].to(T)

when not defined(js):
  proc respToJson*(resp: string): JsObject =
    try:
      result = parseJson(resp)
    except:
      let msg = "Invalid Response: Unable to parse JSON"
      raise InvalidResponseError(msg: msg)
else:
  proc Boolean(o: JsObject): bool {. importc .}

  proc respJson*(data: JsObject): JsObject {. importcpp: "#.json()" .}

  proc respToJson*(resp: JsObject): JsObject =
    if Boolean(resp.ok):
      return respJson(resp)
    let msg = "Invalid Response: Server responsed with code " & $to(resp.status, int)
    raise InvalidResponseError(msg: msg)

  var JSON* {. importc, nodecl .}: JsObject
