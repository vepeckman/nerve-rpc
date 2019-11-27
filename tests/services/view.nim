import nerve

type ViewData* = ref object
  html*: string

service ViewService, "/api/view":

  inject:
    var viewData = ViewData(html: "Hello world")

  proc render(data: string): Future[void] =
    viewData.html = data
    voidFuture()
