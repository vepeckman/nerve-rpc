import jsffi

var console {. importc, nodecl .} : JsObject
var a = newJsObject()
a["method"] = cstring"hello"

let b = $ a["method"]


console.log(c)
