import nerve, nerve/utils

service FileService, "/api/file":

  proc saveFile(filename, data: wstring): Future[wstring]  =
    let file = open(filename)
    result = newFuture[wstring]()
    result.complete("done")
