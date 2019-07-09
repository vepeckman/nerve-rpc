import nerve, nerve/utils

service Hello, "/api/hello":

  proc helloWorld(): Future[wstring] = fwrap("Hello World")

  proc greet(greeting, name: wstring): Future[wstring] = fwrap(greeting & " " & name)
