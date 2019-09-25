import nerve, nerve/web

service GreetingService, "/api/greeting":

  inject:
    var 
      id = 100
      count: int
    var uuid = "asdf"

  proc greet(greeting = "Hello", name = "World" ): Future[string] =
    fwrap(greeting & " " & name)
