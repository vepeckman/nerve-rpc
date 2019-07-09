import nerve, nerve/utils, nerve/drivers

service Hello, "/api/hello":

  proc helloWorld(): Future[wstring] = fwrap("Hello World")

  proc greet(greeting, name: wstring): Future[wstring] = fwrap(greeting & " " & name)
