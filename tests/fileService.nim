import current, current/utils

rpc FileService, "/api/file":

  proc saveFile(filename, data: kstring): Future[kstring]  =
    let file = open(filename)
    result = newFuture[kstring]()
    result.complete("done")
