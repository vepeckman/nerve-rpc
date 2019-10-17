import nerve

type AppData* = ref object
  data*: string

service ModelService, "/api/model":

  inject:
    var db: AppData

  proc updateData(data: string): Future[string] =
    db.data = data
    fwrap(data)
