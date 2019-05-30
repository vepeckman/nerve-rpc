import ../src/current
when not defined(js):
  import asyncdispatch
  type kstring* = string
else:
  import asyncjs
  type kstring* = cstring

type
  Person* = ref object
    name*: kstring
    age*: int
  Parent* = ref object
    self: Person
    children: seq[Person]

rpc example, "/api":
  proc hello(name: kstring): Future[kstring] =
    result = newFuture[kstring]()
    result.complete("Hello " & name)
  
  proc add(x, y: int): Future[int] =
    result = newFuture[int]()
    result.complete(x + y)

  proc newPerson(name: kstring, age: int): Future[Person] =
    result = newFuture[Person]()
    result.complete(Person(name: name, age: age))
