import types, web, promises, clientRuntime

when not defined(js):
  import httpClient

  proc newHttpDriver*(uri: string): NerveDriver =
    let client = newAsyncHttpClient()
    result = proc (req: JsObject): Future[JsObject] {.async.} =
      let res = await client.postContent(uri, $ req)
      result = res.respToJson()

else:

  proc newHttpDriver*(uri: string): NerveDriver =
    result = proc (req: JsObject): Future[JsObject] =
      let msg = newJsObject()
      msg["method"] = cstring"POST"
      msg["body"] = JSON.stringify(req)
      result = fetch(cstring(uri), msg)
        .then(respToJson)
