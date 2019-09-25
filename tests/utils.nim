import asyncHttpServer, asyncdispatch

proc clientJS*(req: Request, path: string, file = "client.js"): Future[void] =
  let headers = newHttpHeaders()
  headers["Content-Type"] = "application/javascript"
  req.respond(Http200, readFile(path & "/nimcache/" & file), headers)

proc indexHtml*(req: Request): Future[void] =
  req.respond(Http200, """<html><head><meta charset="UTF-8"></head><body>Testing</body><script src="client.js"></script></html>""")
