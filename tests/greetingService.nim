import nerve, nerve/web

service GreetingService, "/api/greeting":

  inject:
    var 
      id = 100
      count: int
    var uuid = "asdf"

  proc greet(greeting = wstring("Hello"), name = wstring("World")): Future[wstring] =
    fwrap(greeting & " " & name)
