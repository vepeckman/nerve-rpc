import current, current/utils

type
  Person* = ref object
    name*: kstring
    age*: int
  Parent* = ref object
    self*: Person
    children*: seq[Person]

rpc PersonService, "/api/person":
  proc hello(name = kstring("World")): Future[kstring] =
    result = newFuture[kstring]()
    result.complete("Hello " & name)
  
  proc add(x, y = 0): Future[int] =
    result = newFuture[int]()
    result.complete(x + y)

  proc newPerson(name: kstring, age: int): Future[Person] =
    result = newFuture[Person]()
    result.complete(Person(name: name, age: age))

  proc newParent(person: Person, child: Person): Future[Parent] =
    result = newFuture[Parent]()
    result.complete(Parent(self: person, children: @[child]))
