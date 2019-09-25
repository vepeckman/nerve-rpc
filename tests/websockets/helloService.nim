import nerve

service HelloService, "/api":

  proc greet(name = "world"): Future[string] = fwrap("Hello " & name)
