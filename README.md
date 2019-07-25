# Nerve RPC
Nerve is a RPC framework for building APIs in Nim. It prioritizes flexibility, ease of use, and performance. Nerve provides a compile time macro that generates both an efficient router for dispatching RPC requests on the server, as well as a complete, fully typed, client for both native and JavaScript targets.

### Install
Nerve is available on Nim's builtin package manager, [nimble](https://github.com/nim-lang/nimble).

`nimble install nerve`

### Goals:
- Reduce the incidental complexity around declaring and calling remote procedures. Declaring remote procedures should be as simple as declaring local procedures, and calling them should be as simple as calling local procedures.
- Be fast. Nim generates performant native binaries, and Nerve aims to utilize that speed.
- Have a low cognitive overhead. Nerve does most of the heavy lifting with one macro, supported by a handful of utilities.

### Non-goals:
- Be a general purpose RPC server or client. Nerve implements JSON RPC, so external clients can be written. But it is designed to be used with the built in client, and ease of use for that client is top priority.

# Hello World
```nim
# api.nim
import nerve, nerve/web

service HelloService, "/api/hello":

  # Normal Nim proc definition
  proc helloWorld(): Future[wstring] =   # Return type must be a future 
    result = newFuture[wstring]()   # wstring is compatiable with karax's kstring
    result.complete("Hello world")  # More on why its needed later

  proc greet(greeting, name: wstring): Future[wstring] =
    result = fwrap(greeting & " " & name) # Utility function for declaring and completing a future

# server.nim
import asynchttpserver, asyncdispatch, nerve, nerve/web
import api

let server = newAsyncHttpServer()

proc generateCb(): proc (req: Request): Future[void] {.gcsafe.} =
  # Generate server callback in a function to avoid making the rpc server global
  # A threadlocal var could be used instead, or a manual gcsafe annotation

  let helloServer = HelloService.newServer()

  proc cb(req: Request) {.async, gcsafe.} =
    case req.url.path
    of HelloService.rpcUri: # Const string provided to service
      # Do the rpc dispatch for the service, with the given server
      await req.respond(Http200, $ await HelloService.routeRpc(helloServer, req.body))
    of "/client.js": # Send client file (make sure to compile it first)
      let headers = newHttpHeaders()
      headers["Content-Type"] = "application/javascript"
      await req.respond(Http200, readFile("client.js"), headers)
    of "/": # Send index html
      await req.respond(Http200, """<html><head><meta charset="UTF-8"></head><body>Testing</body><script src="client.js"></script></html>""")
    else: # Not found
      await req.respond(Http404, "Not Found")

  result = cb

waitFor server.serve(Port(1234), generateCb())

# client.nim
import nerve, nerve/promises
import api
# This file can be compiled for native or JS targets

const host = if defined(js): "" else: "http://127.0.0.1:1234"

proc main() {.async.} =
  let helloClient = HelloService.newHttpClient(host)

  echo await helloClient.greet("Hello", "Nerve") # prints Hello World

when defined(js):
  discard main()
else:
  waitFor main()
```

### `service` macro
```nim
macro service*(name: untyped, uri: untyped = nil, body: untyped = nil): untyped
```
Nerve's `service` macro contains most of the functionality of the framework. It takes an identifier, an optional uri, and a list of normal Nim procedures as its body. It produces a RpcService (accessible via the identifier) that can be instantiated into either a client or a server object with fields for each of the provided procs. The client/server object's type is generated with it, but it extends the `RpcServerInst` type provided by Nerve. The macro generates functions to construct new clients and servers, accessible with the service identifier. When compiled for Nim's native target, the macro also generates a dispatch function. The clients (available for both native and JS targets) are provided with a driver to handle constructing and sending the requests. The provided procedures must have a return type of `Future[T]`, as the client will always use these functions asynchronusly.

As the files with the `service` macro need to be compiled for both native and JS targets, those files should focus _only_ on the API functionality. Server instantiation and heavier server logic should go elsewhere. Be aware that any types used by the API files also need to be accessible on both targets.

# nerve/drivers
```nim
type NerveDriver* = proc (req: JsObject): Future[JsObject] {.gcsafe.}
```
As stated earlier, Nerve uses drivers to power its clients. The driver recieves a completed JSON RPC object, and is responsible for sending that to the server and returning the response. The `drivers` module provides common drivers (such as an http driver), but user defined drivers can be used as well.

# nerve/web
Nerve provides a web module to ease some web compatibility issues. The `web` module provides some function and type aliases to allow the same code to be compiled for JS and native targets. It also provides:

### `wstring`
The implementaion of `wstring` (web string) is dependant on the compile target. On the native target, `wstring` is an alias for native Nim string. On the client, it is an alias for JavaScript strings (`cstring` type in Nim). This target dependant alias is needed for full stack Nim code. On the server, Nim's native string serializes to a JavaScript string when the response is serialized to JSON. As the client is receiving this JavaScript string, it must be told to expect a JavaScript string. For any server expecting JS clients, `wstring` *must* be used instead of `string` in any type or function exposed to both the server and the client.

# nerve/promises
The `promsies` module is an extension of the asyncdispatch module for native targets, and the asyncjs module for the JS target. It exports both of those modules, providing all of the typical async functionality of both targets. It also provides some helper functions for dealing with futures, including future chaining with `then`.

# Errors
Errors in RPC calls are propogated to the client. The client code will throw an `RpcError` with information from the error thrown on the server. If the server responds with a non-200 error code, the client throws an `InvalidResponseError`. The server throws errors for incorrect requests, per the JSON-RPC spec.

# Server Injection (experimental)
All of the parameters for the RPC procedures must come from the client. However, Nerve provides a method for injecting variables from the server (such as client connection references, or anything that doesn't serialize well). To define variables for injection, place an `inject` statement in the service declaration. In the inject statement, include `var` definitions for the desired variables. These variable can then be used in any of the RPC procs. The actual injection is done in the `newServer` constructor, where the injected variables are provided to the server.
```nim
service GreetingService, "/api/greeting":

  inject:
    var 
      id = 100
      count: int
    var uuid = "asdf"

  proc greet(greeting = wstring("Hello"), name = wstring("World")): Future[wstring] =
    echo uuid
    fwrap(greeting & " " & name)

let server = GreetingService.newServer(count = 1, uuid = "fdsa")
```

# Gotchas
Nerve trys to be as low friction as possible. However there are a couple edges to watch for.
1) Usages of Nim strings. As stated earlier, Nim strings don't serialize well, and wstrings need to be used for any type compiled under both native and js targets.
2) Procedures under the same RPC server must have different names.
3) Errors for the server injection might reference generated procedures.

# Roadmap
1) Configuration macros. Inform Nerve if it should generate a server, client, or both.
2) A `whenServer` statement to allow situational evaluation for servers.
3) Implement servers for the JS client.
