import ../src/current
when not defined(js):
  import asyncdispatch
  type kstring* = string
else:
  import asyncjs
  type kstring* = cstring

rpc test:
  proc hello(name: kstring): Future[kstring] =
    result = newFuture[kstring]()
    result.complete("Hello " & name)
  
  proc add(x, y: int): Future[int] =
    result = newFuture[int]()
    result.complete(x + y)
