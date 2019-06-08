import json, strutils, sequtils, os
import common

type 
  RequestFormatError* = ref object of CatchableError
  DispatchError* = ref object of CatchableError
  ParameterError* = ref object of CatchableError

proc nerveValidateRequest*(req: JsonNode): bool =
  req.hasKey("jsonrpc") and req["jsonrpc"].getStr() == "2.0" and req.hasKey("id")

proc nerveGetMethod*[T: enum](req: JsonNode): T =
  try:
    parseEnum[T](dispatchPrefix & req["method"].getStr())
  except:
    let msg = if req.hasKey("method"): "No method '" & req["method"].getStr() & "'"
              else: "Request missing method field"
    raise DispatchError(msg: msg, parent: getCurrentException())

proc nerveUnboxParameter*[T](req: JsonNode, param: string, default: T): T =
  try:
    return if req["params"].hasKey(param): req["params"][param].to(T)
           else: default
  except:
    let msg = "Error in param '" & param & "': " & getCurrentExceptionMsg()
    raise ParameterError(msg: msg, parent: getCurrentException())

proc nerveUnboxParameter*[T](req: JsonNode, param: string): T =
  try:
    return req["params"][param].to(T)
  except:
    let msg = "Error in param '" & param & "': " & getCurrentExceptionMsg()
    raise ParameterError(msg: msg, parent: getCurrentException())

proc newNerveError*(code: int, message: string): JsonNode =
  %* {
    "code": code,
    "message": message
  }

proc newNerveError*(code: int, message: string, e: ref CatchableError): JsonNode =
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

export parseJson
