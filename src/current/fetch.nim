import jsffi, asyncjs

proc fetch*(uri: cstring): Future[JsObject] {. importc .}
proc fetch*(uri: cstring, data: JsObject): Future[JsObject] {. importc .}
proc then*[T, R](promise: Future[T], next: proc (data: T): Future[R]): Future[R] {. importcpp: "#.then(@)" .}
proc then*[T, R](promise: Future[T], next: proc (data: T): R): Future[R] {. importcpp: "#.then(@)" .}
proc then*[T](promise: Future[T], next: proc(data: T)): Future[void] {. importcpp: "#.then(@)" .}

export Future
