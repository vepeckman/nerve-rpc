when not defined(js):
  import json, asyncdispatch, httpClient

  type HttpDriver* = ref object
    client: AsyncHttpClient
    uri: string

  proc send*[T](driver: HttpDriver, req: JsonNode): Future[T] {.async.} =
    let res = await driver.client.postContent(driver.uri, $ req)
    result = res.parseJson().to(T)

  proc newHttpDriver*(uri: string): HttpDriver = HttpDriver(client: newAsyncHttpClient(), uri: uri)
