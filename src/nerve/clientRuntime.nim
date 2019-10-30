import json
import promises

type
  InvalidResponseError* = ref object of CatchableError
  RpcError* = ref object of CatchableError

proc handleRpcResponse*[T](rpcResponse: JsonNode): T =
  if hasKey(rpcResponse, "error"):
    let error = rpcResponse["error"]
    let msg = $error["message"] & ": " & $error["data"]["msg"] & "\n" & $error["data"]["stackTrace"] & "\n"
    raise RpcError(msg: msg)
  rpcResponse["result"].to(T)

proc respToJson*(resp: string): JsonNode =
  try:
    result = parseJson(resp)
  except:
    let msg = "Invalid Response: Unable to parse JSON"
    raise InvalidResponseError(msg: msg)

proc respToJson*(resp: cstring): JsonNode = respToJson($ resp)

when defined(js):
  import jsffi

  proc Boolean(o: JsObject): bool {. importc .}
  
  proc respText*(data: JsObject): Future[cstring] {. importcpp: "#.text()" .}

  proc handleFetchResponse*(resp: JsObject): Future[JsonNode] =
    if Boolean(resp.ok):
      return resp.respText().then(respToJson)
    let msg = "Invalid Response: Server responsed with code " & $to(resp.status, int)
    raise InvalidResponseError(msg: msg)
