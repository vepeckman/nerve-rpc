import json, strutils
import common

type 
  DispatchError* = object of CatchableError
  ParameterError* = object of CatchableError
  MethodError* = object of CatchableError

proc nerveUnboxParameter*[T](req: JsonNode, param: string, default: T): T =
  if req["params"].hasKey(param):
    req["params"][param].to(T)
  else: default

proc nerveUnboxParameter*[T](req: JsonNode, param: string): T =
  req["params"][param].to(T)

proc nerveGetMethod*[T: enum](req: JsonNode): T =
  parseEnum[T](dispatchPrefix & req["method"].getStr())
