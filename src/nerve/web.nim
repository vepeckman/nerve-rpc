import json
export json
when not defined(js):

  type wstring* = string
  type JsObject* = JsonNode

  template toJs*(x: untyped): untyped = % x
  const newJsObject* = newJObject


else:
  import jsffi

  type wstring* = cstring

  var JSON* {. importc, nodecl .}: JsObject
  proc parseJson* (data: cstring): JsObject {. importcpp: "JSON.parse(#)", nodecl .}
  proc `$`* (jsObject: JsObject): string {. importcpp: "JSON.stringify(#)", nodecl .}

  template hasKey* (obj: JsObject, key: untyped): untyped = obj.hasOwnProperty(key)

  template newJNull*(): untyped = jsNull

  export jsffi
