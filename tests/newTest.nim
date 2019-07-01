import nerve/service, nerve/newclient, nerve/drivers, nerve/utils
import macros

service Hello, "/api/hello":

  proc helloWorld(): Future[wstring] = fwrap("Hello World")

  proc greet(greeting, name: wstring): Future[wstring] = fwrap(greeting & " " & name)

let helloClient = client(Hello, echoDriver)
discard helloClient.helloWorld()
