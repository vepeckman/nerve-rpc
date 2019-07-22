import asyncdispatch, httpclient
import newApi, nerve, nerve/drivers

let client = Hello.newClient(newHttpDriver("http://127.0.0.1:1234/rpc"))

proc main() {.async.} =
  let greeting = await client.greet()
  echo greeting

waitFor main()
