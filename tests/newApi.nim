import nerve, nerve/drivers, nerve/web, nerve/utils

service Hello, "":
  proc greet(): Future[wstring] = fwrap("Hello world")
