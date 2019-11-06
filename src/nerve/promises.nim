when defined(js):
  import asyncjs, jsffi

  proc fetch*(uri: cstring): Future[JsObject] {. importc .}
  proc fetch*(uri: cstring, data: JsObject): Future[JsObject] {. importc .}
  proc then*[T, R](promise: Future[T], next: proc (data: T): Future[R]): Future[R] {. importcpp: "#.then(@)" .}
  proc then*[T, R](promise: Future[T], next: proc (data: T): R): Future[R] {. importcpp: "#.then(@)" .}
  proc then*[T](promise: Future[T], next: proc(data: T)): Future[void] {. importcpp: "#.then(@)" .}
  proc then*[T](promise: Future[void], next: proc(): T): Future[T] {. importcpp: "#.then(@)" .}
  proc then*[T](promise: Future[void], next: proc(): Future[T]): Future[T] {. importcpp: "#.then(@)"}
  proc catch*[T, R](promise: Future[T], next: proc (data: T): Future[R]): Future[R] {. importcpp: "#.catch(@)" .}
  proc catch*[T, R](promise: Future[T], next: proc (data: T): R): Future[R] {. importcpp: "#.catch(@)" .}
  proc catch*[T](promise: Future[T], next: proc(data: T)): Future[void] {. importcpp: "#.catch(@)" .}

  proc newFuture[T](it: T): Future[T] {. importcpp: "Promise.resolve(#)" .}
  proc newFuture(): Future[void] {. importcpp: "Promise.resolve" .}
  proc voidFuture*(): Future[void] = newFuture()
  proc futureWrap*[T](it: T, procname = ""): Future[T] = newFuture(it)

  export asyncjs

else:
  import asyncdispatch

  proc voidFuture*(): Future[void] =
    result = newFuture[void]()
    result.complete()

  proc then*[T, R](future: Future[T], cb: proc (t: T): R {.gcsafe.}): Future[R] =
    let rv = newFuture[R]("then")
    future.callback = proc (data: Future[T])  =
      when $R != "void":
        rv.complete(cb(data.read))
      else:
        rv.complete()
    result = rv

  proc then*[T, R](future: Future[T], cb: proc (t: T): Future[R] {.gcsafe.}): Future[R] =
    let rv = newFuture[R]("then")
    future.callback = proc (data: Future[T])  =
      let intermediate = cb(data.read)
      intermediate.callback = proc (otherData: Future[R]) =
        when $R != "void":
          rv.complete(otherData.read)
        else:
          rv.complete()
    result = rv

  proc then*[T](future: Future[T], cb: proc (t: T) {.gcsafe.}): Future[void] =
    let rv = newFuture[void]("then")
    future.callback = proc (data: Future[T])  =
      cb(data.read)
      rv.complete()
    result = rv

  proc then*[T](future: Future[void], cb: proc(): T {.gcsafe.}): Future[T] =
    let rv = newFuture[T]("then")
    future.callback = proc (data: Future[void]) =
      when $T != "void":
        rv.complete(cb())
      else:
        cb()
        rv.complete()
    result = rv

  proc then*[T](future: Future[void], cb: proc(): Future[T] {.gcsafe.}): Future[T] =
    let rv = newFuture[T]("then")
    future.callback = proc (data: Future[void]) =
      let intermediate = cb()
      intermediate.callback = proc (otherData: Future[T]) =
        when $T != "void":
          rv.complete(otherData.read)
        else:
          rv.complete()
    result = rv

  proc futureWrap*[T](it: T, procname = ""): Future[T] =
    result = newFuture[T](procname)
    result.complete(it)

  export asyncdispatch
