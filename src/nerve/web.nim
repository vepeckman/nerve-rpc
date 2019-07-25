when not defined(js):
  import json

  type wstring* = string
  type JsObject* = JsonNode

  template toJs*(x: untyped): untyped = % x
  const newJsObject* = newJObject

  export json

else:
  import jsffi

  type wstring* = cstring

  var JSON* {. importc, nodecl .}: JsObject
  proc parseJson* (data: cstring): JsObject {. importcpp: "JSON.parse(#)", nodecl .}
  proc `$`* (jsObject: JsObject): string {. importcpp: "JSON.stringify(#)", nodecl .}

  template hasKey* (obj: JsObject, key: untyped): untyped = obj.hasOwnProperty(key)

  template newJNull*(): untyped = jsNull

  export jsffi
