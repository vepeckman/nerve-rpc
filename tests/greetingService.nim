import nerve, nerve/utils

service GreetingService, "/api/greeting":

  proc greet(greeting = wstring("Hello"), name = wstring("World")): Future[wstring] =
    fwrap(greeting & " " & name)
