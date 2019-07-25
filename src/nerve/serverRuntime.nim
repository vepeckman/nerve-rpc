import strutils, sequtils
import web, promises, common
when not defined(js):
  import os

type 
  RequestFormatError* = ref object of CatchableError
  DispatchError* = ref object of CatchableError
  ParameterError* = ref object of CatchableError

when not defined(js):
  proc nerveValidateRequest*(req: JsObject): bool =
    req.hasKey("jsonrpc") and req["jsonrpc"].getStr() == "2.0" and req.hasKey("id")
else:
  proc nerveValidateRequest*(req: JsObject): bool =
    req.hasOwnProperty("jsonrpc") and (req["jsonrpc"].to(cstring) == "2.0") and req.hasOwnProperty("id")

proc nerveGetMethod*[T: enum](req: JsObject): T =
  try:
    parseEnum[T](dispatchPrefix & req["method"].getStr())
  except:
    let msg = if req.hasKey("method"): "No method '" & req["method"].getStr() & "'"
              else: "Request missing method field"
    raise DispatchError(msg: msg, parent: getCurrentException())

proc nerveUnboxParameter*[T](req: JsObject, param: string, default: T): T =
  try:
    return if req["params"].hasKey(param): req["params"][param].to(T)
           else: default
  except:
    let msg = "Error in param '" & param & "': " & getCurrentExceptionMsg()
    raise ParameterError(msg: msg, parent: getCurrentException())

proc nerveUnboxParameter*[T](req: JsObject, param: string): T =
  try:
    return req["params"][param].to(T)
  except:
    let msg = "Error in param '" & param & "': " & getCurrentExceptionMsg()
    raise ParameterError(msg: msg, parent: getCurrentException())

when not defined(js):

  proc newNerveResponse*(): JsObject =
    %* {"jsonrpc": "2.0", "id": newJNull()}

  proc newNerveError*(code: int, message: string): JsObject =
    %* {
      "code": code,
      "message": message
    }

  proc newNerveError*(code: int, message: string, e: ref CatchableError): JsObject =
    let dir = getCurrentDir()
    let stackTrace = e.getStackTraceEntries()
      .filterIt(`$`(it.filename).find(dir) != -1 and 
                `$`(it.procname).find(dispatchPrefix) == -1)
      .mapIt($it.filename & "(" & $it.line & ")" & "  " & $it.procname)
      .join("\n")
    return %* {
      "code": code,
      "message": message,
      "data": {
        "msg": e.msg,
        "stackTrace": if defined(release): "" else: stackTrace
      }
    }

else:

  proc newNerveResponse*(): JsObject =
    result = newJsObject()
    result["jsonrpc"] = cstring"2.0"
    result["id"] = jsNull

  proc newNerveError*(code: int, message: string): JsObject =
    result = newJsObject()
    result["code"] = code
    result["message"] = message

  proc newNerveError*(code: int, message: string, e: ref CatchableError): JsObject =
    result = newJsObject()
    result["code"] = code
    result["message"] = message
    result["data"] = newJsObject()
    result["data"]["msg"] = e.msg
    result["data"]["stackTrace"] = getStackTrace()
