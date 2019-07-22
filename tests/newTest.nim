import nerve, nerve/utils, nerve/drivers, nerve/web

service Hello, "/api/hello":

  proc helloWorld(): Future[wstring] = fwrap(wstring"Hello World")

  proc greet(greeting, name: wstring): Future[wstring] = fwrap(greeting & " " & name)

let server = Hello.newClient(newHttpDriver(""))
