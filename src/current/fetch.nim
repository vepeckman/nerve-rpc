import jsffi, asyncjs, json

proc fetch*(uri: cstring): Future[JsObject] {. importc .}
proc fetch*(uri: cstring, data: JsObject): Future[JsObject] {. importc .}
proc then*[T, R](promise: Future[T], next: proc (data: T): Future[R]): Future[R] {. importcpp: "#.then(@)" .}
proc then*[T, R](promise: Future[T], next: proc (data: T): R): Future[R] {. importcpp: "#.then(@)" .}
proc then*[T](promise: Future[T], next: proc(data: T)): Future[void] {. importcpp: "#.then(@)" .}

var JSON* {. importc, nodecl .}: JsObject
proc respJson*(data: JsObject): JsonNode {. importcpp: "#.json()" .}

export Future
