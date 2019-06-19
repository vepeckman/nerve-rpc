import nerve, nerve/utils

rpc FileService, "/api/file":

  proc saveFile(filename, data: wstring): Future[wstring]  =
    let file = open(filename)
    result = newFuture[wstring]()
    result.complete("done")
