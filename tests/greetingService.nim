import current, current/utils

rpc GreetingService, "/api/greeting":

  proc greet(greeting = kstring("Hello"), name = kstring("World")): Future[kstring] =
    result = newFuture[kstring]()
    result.complete(greeting & " " & name)
