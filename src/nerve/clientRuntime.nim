import utils

type
  InvalidResponseError* = ref object of CatchableError
  RpcError* = ref object of CatchableError


proc handleRpcResponse*[T](rpcResponse: WObject): T =
  if rpcResponse.hasKey("error"):
    let error = rpcResponse["error"]
    let msg = $error["message"].to(wstring) & ": " & $error["data"]["msg"].to(wstring) & "\n" & $error["data"]["stackTrace"].to(wstring) & "\n"
    raise RpcError(msg: msg)
  rpcResponse["result"].to(T)

when not defined(js):
  proc respToJson*(resp: string): WObject =
    try:
      result = parseJson(resp)
    except:
      let msg = "Invalid Response: Unable to parse JSON"
      raise InvalidResponseError(msg: msg)
else:
  proc Boolean(o: WObject): bool {. importc .}

  proc respJson*(data: WObject): WObject {. importcpp: "#.json()" .}

  proc respToJson*(resp: WObject): WObject =
    if Boolean(resp.ok):
      return respJson(resp)
    let msg = "Invalid Response: Server responsed with code " & $to(resp.status, int)
    raise InvalidResponseError(msg: msg)

  var JSON* {. importc, nodecl .}: JsObject
