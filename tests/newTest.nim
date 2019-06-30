import nerve/service, nerve/newserver, nerve/utils
import macros

service Hello, "/api/hello":

  proc helloWorld(): Future[wstring] = fwrap("Hello World")

  proc greet(greeting, name: wstring): Future[wstring] = fwrap(greeting & " " & name)

let helloServer = server(Hello)
discard helloServer.helloWorld()
