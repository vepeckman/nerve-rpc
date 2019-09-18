import nerve, nerve/web

service FileService, "/api/file":

  proc saveFile(filename, data: string): Future[string]  =
    let file = open(filename)
    result = newFuture[string]()
    result.complete("done")
