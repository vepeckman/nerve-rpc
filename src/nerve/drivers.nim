import types, web, promises, clientRuntime

when not defined(js):
  import httpClient

  proc newHttpDriver*(uri: string): NerveDriver =
    let client = newAsyncHttpClient()
    result = proc (req: JsonNode): Future[JsonNode] {.async.} =
      let res = await client.postContent(uri, $ req)
      result = res.respToJson()

else:

  proc newHttpDriver*(uri: string): NerveDriver =
    result = proc (req: JsonNode): Future[JsonNode] =
      let msg = newJsObject()
      msg["method"] = cstring"POST"
      msg["body"] = cstring($ req)
      result = fetch(cstring(uri), msg)
        .then(handleFetchResponse)
