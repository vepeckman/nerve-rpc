import ../src/current
when not defined(js):
  import asyncdispatch
else:
  import asyncjs

rpc:
  proc hello*(name: string): Future[string] =
    result = newFuture[string]()
    result.complete("Hello " & name)
  
  proc add*(x, y: int): Future[int] =
    result = newFuture[int]()
    result.complete(x + y)
