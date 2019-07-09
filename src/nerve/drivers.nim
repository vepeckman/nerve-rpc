when not defined(js):
  import asyncdispatch, httpClient
  import types, utils, clientRuntime

  proc newHttpDriver*(uri: string): NerveDriver =
    let client = newAsyncHttpClient()
    result = proc (req: WObject): Future[WObject] {.async.} =
      let res = await client.postContent(uri, $ req)
      result = res.respToJson()
else:
  import asyncjs
  import types, utils, clientRuntime

  proc newHttpDriver*(uri: string): NerveDriver =
    result = proc (req: WObject): Future[WObject] =
      let msg = newJsObject()
      msg["method"] = cstring"POST"
      msg["body"] = JSON.stringify(req)
      result = fetch(cstring(uri), msg)
        .then(respToJson)
