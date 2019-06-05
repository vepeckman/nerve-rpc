import current, current/utils
when not defined(js):
  proc failure() =
    raise new(KeyError)

rpc FileService, "/api/file":

  proc saveFile(filename, data: kstring): Future[kstring]  =
    failure()
    result = newFuture[kstring]()
    result.complete("done")
