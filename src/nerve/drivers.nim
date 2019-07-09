when not defined(js):
  import asyncdispatch, httpClient
  import types, utils, clientRuntime

  proc newHttpDriver*(uri: string): NerveDriver =
    let client = newAsyncHttpClient()
    result = proc (req: WObject): Future[WObject] {.async.} =
      let res = await client.postContent(uri, $ req)
      result = res.respToJson()
