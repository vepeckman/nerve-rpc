when not defined(js):
  import json, asyncdispatch

  type NerveDriver*[T] = proc (req: JsonNode): Future[T]

  proc echoDriver*[T] (req: JsonNode): Future[T] =
    result = newFuture[T]()
    result.complete(req.to(T))
