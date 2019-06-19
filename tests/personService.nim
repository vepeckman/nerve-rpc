import current, current/utils

type
  Person* = ref object
    name*: wstring
    age*: int
  Parent* = ref object
    self*: Person
    children*: seq[Person]

rpc PersonService, "/api/person":
  proc helloWorld(): Future[wstring] =
    result = newFuture[wstring]()
    result.complete("Hello world")

  proc hello(name = wstring("World")): Future[wstring] =
    result = newFuture[wstring]()
    result.complete("Hello " & name)
  
  proc add(x, y = 0): Future[int] =
    result = newFuture[int]()
    result.complete(x + y)

  proc newPerson(name: wstring, age: int): Future[Person] =
    result = newFuture[Person]()
    result.complete(Person(name: name, age: age))

  proc newParent(person: Person, child: Person): Future[Parent] =
    result = newFuture[Parent]()
    result.complete(Parent(self: person, children: @[child]))
