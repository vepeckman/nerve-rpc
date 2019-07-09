import strutils, sequtils, os
when not defined(js):
  import json, asyncdispatch, os
  export json, asyncdispatch
else:
  import jsffi, asyncjs
  export jsffi, asyncjs
import common, utils

type 
  RequestFormatError* = ref object of CatchableError
  DispatchError* = ref object of CatchableError
  ParameterError* = ref object of CatchableError

when not defined(js):
  proc nerveValidateRequest*(req: WObject): bool =
    req.hasKey("jsonrpc") and req["jsonrpc"].getStr() == "2.0" and req.hasKey("id")
else:
  proc nerveValidateRequest*(req: WObject): bool =
    req.hasOwnProperty("jsonrpc") and (req["jsonrpc"].to(cstring) == "2.0") and req.hasOwnProperty("id")

proc nerveGetMethod*[T: enum](req: WObject): T =
  try:
    parseEnum[T](dispatchPrefix & req["method"].getStr())
  except:
    let msg = if req.hasKey("method"): "No method '" & req["method"].getStr() & "'"
              else: "Request missing method field"
    raise DispatchError(msg: msg, parent: getCurrentException())

proc nerveUnboxParameter*[T](req: WObject, param: string, default: T): T =
  try:
    return if req["params"].hasKey(param): req["params"][param].to(T)
           else: default
  except:
    let msg = "Error in param '" & param & "': " & getCurrentExceptionMsg()
    raise ParameterError(msg: msg, parent: getCurrentException())

proc nerveUnboxParameter*[T](req: WObject, param: string): T =
  try:
    return req["params"][param].to(T)
  except:
    let msg = "Error in param '" & param & "': " & getCurrentExceptionMsg()
    raise ParameterError(msg: msg, parent: getCurrentException())

when not defined(js):
  proc newNerveError*(code: int, message: string): WObject =
    %* {
      "code": code,
      "message": message
    }

  proc newNerveError*(code: int, message: string, e: ref CatchableError): WObject =
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
  proc newNerveError*(code: int, message: string): WObject =
    result = newJsObject()
    result["code"] = code
    result["message"] = message

  proc newNerveError*(code: int, message: string, e: ref CatchableError): WObject =
    result = newJsObject()
    result["code"] = code
    result["message"] = message
    result["data"] = newJsObject()
    result["data"]["msg"] = e.msg
    result["data"]["stackTrace"] = getStackTrace()
