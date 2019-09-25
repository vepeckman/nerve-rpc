import nerve, nerve/web

type
  Person* = ref object
    name*: string
    age*: int
  Parent* = ref object
    self*: Person
    children*: seq[Person]

service PersonService, "/api/person":
  proc helloWorld(): Future[string] = fwrap("Hello world")

  proc hello(name = "World"): Future[string] = fwrap("Hello " & name)
  
  proc add(x, y = 0): Future[int] = fwrap(x + y)

  proc newPerson(name: string, age: int): Future[Person] = fwrap(Person(name: name, age: age))

  proc newParent(person: Person, child: Person): Future[Parent] = fwrap(Parent(self: person, children: @[child]))
