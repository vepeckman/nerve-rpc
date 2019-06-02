import current, current/utils
when not defined(js):
  proc failure() =
    assert(true == false)

rpc FileService, "/api/file":

  proc saveFile(filename, data: kstring): Future[kstring]  =
    failure()
    result = newFuture[kstring]()
    result.complete("done")
