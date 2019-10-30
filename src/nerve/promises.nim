import macros, json

when defined(js):
  import asyncjs, jsffi

  proc fetch*(uri: cstring): Future[JsObject] {. importc .}
  proc fetch*(uri: cstring, data: JsObject): Future[JsObject] {. importc .}
  proc then*[T, R](promise: Future[T], next: proc (data: T): Future[R]): Future[R] {. importcpp: "#.then(@)" .}
  proc then*[T, R](promise: Future[T], next: proc (data: T): R): Future[R] {. importcpp: "#.then(@)" .}
  proc then*[T](promise: Future[T], next: proc(data: T)): Future[void] {. importcpp: "#.then(@)" .}
  proc catch*[T, R](promise: Future[T], next: proc (data: T): Future[R]): Future[R] {. importcpp: "#.catch(@)" .}
  proc catch*[T, R](promise: Future[T], next: proc (data: T): R): Future[R] {. importcpp: "#.catch(@)" .}
  proc catch*[T](promise: Future[T], next: proc(data: T)): Future[void] {. importcpp: "#.catch(@)" .}

  type Promise = distinct JsObject
  var PromiseObj {. importc: "Promise", nodecl .}: Promise
  proc newFuture[T](it: T): Future[T] {. importcpp: "Promise.resolve(#)" .}
  proc resolve[T](promise: Promise, it: T): Future[T] {.importcpp: "#.resolve(@)".}
  proc fwrap*[T](it: T, procname = ""): Future[T] = newFuture(it)

  export asyncjs

else:
  import asyncdispatch

  proc then*[T, R](future: Future[T], cb: proc (t: T): R {.gcsafe.}): Future[R] =
    let rv = newFuture[R]("then")
    future.callback = proc (data: Future[T])  =
      rv.complete(cb(data.read))
    result = rv

  proc then*[T, R](future: Future[T], cb: proc (t: T): Future[R] {.gcsafe.}): Future[R] =
    let rv = newFuture[R]("then")
    future.callback = proc (data: Future[T])  =
      let intermediate = cb(data.read)
      intermediate.callback = proc (otherData: Future[R]) =
        rv.complete(otherData.read)
    result = rv

  proc then*[T](future: Future[T], cb: proc (t: T) {.gcsafe.}): Future[void] =
    let rv = newFuture[void]("then")
    future.callback = proc (data: Future[T])  =
      cb(data.read)
      rv.complete()
    result = rv

  proc fwrap*[T](it: T, procname = ""): Future[T] =
    result = newFuture[T](procname)
    result.complete(it)

  export asyncdispatch
