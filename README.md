# Nerve RPC
Nerve is a RPC framework in Nim designed to build Web facing APIs. It prioritizes flexibility, ease of use, and performance. Nerve provides a compile time macro that generates both an efficient router for dispatching RPC requests on the server, as well as a complete, fully typed, client for Nim's Javascript runtime. 

### Goals:
- Reduce the incidental complexity around declaring and calling remote procedures. Declaring remote procedures should be as simple as declaring local procedures, and calling them should be as simple as calling local procedures.
- Be fast. Nim generates performant native binaries, and Nerve aims to utilize that speed.
- Have a low cognitive overhead. Nerve does most of the heavy lifting with one macro, supported by a handful of utilities.

### Non-goals:
- Be a general purpose RPC server or client. Nerve implements JSON RPC, so external clients can be written. But it is designed to be used with the built in client, and ease of use for that client is top priority.

# Hello World
```nim
# api.nim
import nerve, nerve/utils

rpc Hello, "/api/hello": # The identifier for the rpc object
                         # As well as the url the service will use

  # Normal Nim proc definition
  proc helloWorld(): Future[wstring] =   # Return type must be a future 
    result = newFuture[wstring]()   # wstring is compatiable with karax's kstring
    result.complete("Hello world")  # More on why its needed later

  proc greet(greeting, name: wstring): Future[wstring] =
    result = fwrap(greeting & " " & name) # Utility function for declaring and completing a future

# server.nim
import asynchttpserver, asyncdispatch, json
import nerve/utils, api

var server = newAsyncHttpServer()
proc cb(req: Request) {.async.} =
  case req.url.path
  of "/": # Send index html
    await req.respond(Http200, """<html><head><meta charset="UTF-8"></head><body>Testing</body><script src="client.js"></script></html>""")
  of "/client.js": # Send client file (make sure to compile it first)
    await req.respond(Http200, readFile("client.js"))
  of Hello.rpcUri: # Const string provided to rpc macro
    await req.respond(Http200, $ await Hello.routeRpc(req.body)) # Do the RPC dispatch and return the response
  else: # Not found
    await req.respond(Http404, "Not found")

waitFor server.serve(Port(8080), cb)

# client.nim
import asyncjs
import api

proc main() {.async.} =
  echo await Hello.greet("Hello", "Nerve") # prints "Hello Nerve" to the console

discard main()
```

### `rpc` macro
```nim
macro rpc(name, uri, body: untyped): untyped
```
Nerve's `rpc` macro contains most of the functionality of the framework. It takes an identifier, a uri, and a list of normal Nim procedures as its body. It produces an object (accessible via the identifier) that has fields for each of the given procedures. The object's type is generated with it, but it extends the `RpcServer` type provided by Nerve. When compiled for Nim's native target, the macro also generates a dispatch function. When compiled for Nim's JS target, the macro modifies the body of each provided procedure, replacing the server code with the code necessary to create a request, send it, and return the response. The provided procedures must have a return type of `Future[T]`, as the client will always use these functions asynchronusly.

As the files with the `rpc` macro need to be compiled for both native and JS targets, those files should focus _only_ on the API functionality. Server instantiation and heavier server logic should go elsewhere. Be aware that any types used by the API files also need to be accessible on both targets.

# Utilities
Nerve provides some utility functions, located in `nerve/utils`. These utilities are provided to make 

### `wstring`
The implementaion of `wstring` (web string) is dependant on the compile target. On the native target, `wstring` is an alias for native Nim string. On the client, it is an alias for JavaScript strings (`cstring` type in Nim). This target dependant alias is needed for full stack Nim code. On the server, Nim's native string serializes to a JavaScript string when the response is serialized to JSON. As the client is receiving this JavaScript string, it must be told to expect a JavaScript string. `wstring` *must* be used instead of `string` in any type or function exposed to both the server and the client.

### `rpcUri`
```nim
macro rpcUri(rpc: RpcServer): untyped
```
This macro takes an RPC object and returns the constant uri string. This is a macro rather than a normal procedure so the constant string can be used in `case` branches.

### `routeRpc`
```nim
macro routeRpc*(rpc: RpcServer, req: JsonNode): untyped

macro routeRpc*(rpc: RpcServer, req: string): untyped
```
This macro takes an RPC object and an RPC request, either a string or JSON. The client sends requests over HTTP, as the body of a post request. The client should always send valid JSON and a valid request. The macro inserts a link to a generated dispatch function from the `rpc` macro. 

### `fwrap`
```nim
proc fwrap*[T](it: T): Future[T]
```
A simple proc for wrapping a future, added to assist with future returns from RPC procs.

# Errors
Errors in RPC calls are propogated to the client. The client code will throw an `RpcError` with information from the error thrown on the server. If the server responds with a non-200 error code, the client throws an `InvalidResponseError`. The server throws errors for incorrect requests, per the JSON-RPC spec.

# Gotchas
Nerve trys to be as low friction as possible. However there are a couple edges to watch for.
1) Usages of Nim strings. As stated earlier, Nim strings don't serialize well, and wstrings need to be used for any type compiled under both native and js targets.
2) Procedures under the same RPC server must have different names.

# Roadmap
Nerve was written primarily for my use, as a way to speed up the process of writing web APIs. It has the majority of features I set out to include, but I'm open to new features (or pull requests) if anyone else finds this project useful.
