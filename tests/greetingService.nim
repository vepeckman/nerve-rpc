import current, current/utils

rpc GreetingService, "/api/greeting":

  proc greet(greeting = wstring("Hello"), name = wstring("World")): Future[wstring] =
    result = newFuture[wstring]()
    result.complete(greeting & " " & name)
