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

The following `main.nim` is a Nerve server, native client, and Javascript client. Compile and run the server with `nim c -r -d:nerveServer main.nim`. In a seperate tab, compile and run the native client with `nim c -r -d:nerveClient main.nim`. Compile the Javascript client with `nim js -d:nerveClient main.nim` and open `localhost:1234` in a browser to view the browser console.

```nim
# main.nim
import nerve

# Declare the service with Nerve's service macro, provide an identifier and uri
service HelloService, "/api":

  # Declare procs for the service using Nim's normal proc definitions
  proc greet(name = "world"): Future[string] = futureWrap("Hello " & name)

  proc runTask(task: string): Future[void] =
    echo "Running task " & task
    result = voidFuture()


  # Modifier macro to setup the http server
  server:

    # Import and setup Nim's built in http server
    import asyncHttpServer
    let server = newAsyncHttpServer()

    # Create a RPC server for the declared Nerve service
    let helloServer = HelloService.newServer()

    # Handler for the http server
    proc cb (req: Request) {.async, gcsafe.} =
      case req.url.path
      of HelloService.rpcUri:
        # If a request has the service uri, dispatch the request to the service
        await req.respond(Http200, $ await helloServer.routeRpc(req.body))
      of "/client.js":
        # JavaScript file for the frontend
        let headers = newHttpHeaders()
        headers["Content-Type"] = "application/javascript"
        await req.respond(Http200, readFile("main.js"), headers)
      of "/":
        # HTML file for the frontend
        await req.respond(Http200, """<html><head><meta charset="UTF-8"></head><body>Testing</body><script src="client.js"></script></html>""")
      else:
        await req.respond(Http404, "Not Found")

    waitFor server.serve(Port(1234), cb)


  # Modifier macro to setup the http client
  client:
    const host = if defined(js): "" else: "http://127.0.0.1:1234"

    proc main() {.async.} =
      # Create a RPC client for the declared Nerve service
      let helloClient = HelloService.newHttpClient(host)

      # Use the remote methods defined on the service

      echo await helloClient.greet("Nerve") # Prints "Hello Nerve" to the console
      await helloClient.runTask("serverside_task") # Prints "Running task serverside_task" on the server

    when defined(js):
      discard main()
    else:
      waitFor main()
```

# Overview

The majority of Nerve's functionality is provided by the main `nerve` module.

## `service` macro

```nim
macro service*(name: untyped, uri: untyped = nil, body: untyped = nil): untyped
```

Nerve's `service` macro is responsible for doing all of the setup and code generation required for RPC services. It takes an identifier, an optional uri, and a list of normal Nim procedures as its body. It produces an RpcService (accessible via the identifier) that can be instantiated into either a client or a server object with fields for each of the provided procs. The macro generates an object type that extends the `RPCServerInst` type provided by Nerve that describes instances of service clients and service servers. The macro also generates a dispatch function that dispatches incoming requests to the correct proc on the service. The provided procedures must have a return type of `Future[T]`, as the client will always use these functions asynchronusly.



By default, the `service` macro produces both the client and server code for each service. Nerve provides serveral methods for controlling what code is generated (see configuration), which could be desirable if proc implementations contain code specific to the server target. As file with the `service` macro can be compiled for both native and JS targets, those files should focus _only_ on the API functionality. Be aware that any types used and any modules imported by the API files also should to be accessible on both targets. The `serverImports` macro modifier can be used to import certain modules only on the server, which is useful for any proc implementation containing server specific code.

## `newServer` macro

```nim
macro newServer*(rpc: static[RpcService], injections: varargs[untyped]): untyped
```

The `newServer` macro takes a service defined with `service` and instantiates a RPC server. The created service instance can then use `routeRpc` to take a `string` or `JsonNode`, dispatch the request, and return a response. The server instance provides only this dispatch functionality; it does not listen to any ports or otherwise connect to the network. The user must setup their HTTP server (or server for any other protocol) and then call the RPC server when a request comes that should be handled by the RPC server. The `newServer` macro optionally takes injected variables, see the `inject` modifier for more information.

## `newClient` and `newHttpClient` macros

```nim
macro newClient*(rpc: static[RpcService], driver: NerveDriver): untyped
macro newHttpClient*(rpc: static[RpcService], host: static[string] = ""): untyped
```

The `newClient` macro takes a service defined with `service` and a driver, and instantiates a RPC client. The driver is a function responsible for making the requests to the server and returning the response. Drivers can be found in the `nerve/driver` module, or user defined. The `newHttpClient` macro combines the `newClient` macro with the an HTTP driver for convenience.

## `serverImport` modifier

```nim
macro serverImport*(imports: untyped)
```

In the web domain, its likely that servers will contain server specific code from modules that interact with databases, other servers, or filesystems. The `serverImport` modifier gives the `service` macro the import modules only when the service is configured as a server.

```nim
service FileService, "/api/file":
    serverImport(os)
    
    proc save(filename, text: string): Future[void] =
        # Use procs from the os module here
```

## `inject` modifier

```nim
macro inject*(injections: untyped)
```



All of the parameters for the RPC procedures must come from the client. However, Nerve provides a method for injecting variables from the server (such as client connection references, a service client, or anything that doesn't serialize well). To define variables for injection, place an `inject` statement in the service declaration. In the inject statement, include `var` definitions for the desired variables. These variable can then be used in any of the RPC procs. The actual injection is done in the `newServer` constructor, where the injected variables are provided to the server.

```nim
service GreetingService, "/api/greeting":
    inject:
        var 
          id = 100
          count: int
        var uuid = "asdf"
        
    proc greet(greeting = "Hello", name = "World"): Future[string] =
        echo uuid
        futureWrap(greeting & " " & name)

let server = GreetingService.newServer(count = 1, uuid = "fdsa")
```

## `server` and `client` modifiers

```nim
macro server*(serverStmts: untyped)
macro client*(clientStmts: untyped)
```

The RPC clients and servers can be setup anywhere in the codebase, and can even be instantiated multiple times. However, it might be convenient to initialize a single instance of a client and server in the same file as the service declaration. The `server` and `client` modifiers enable this functionality. Each takes a code block, and executes that codeblock if the services is configured as a server or client, respectively (both will be executed if the service is configured to be both a server and a client). These macros can also be used to setup all the server and client code (as in the Hello World example), though this is only recommended for simple server/client setups.

```nim
service GreetingService, "/api/greeting":
    proc greet(greeting = "Hello", name = "World"): Future[string] =
     futureWrap(greeting & " " & name)
     
    server:
        let greetingServer* = GreetingService.newServer()
        
    client:
        let greetingClient* = GreetingService.newHttpClient()
```

## nerve/drivers

```nim
type NerveDriver* = proc (req: JsonNode): Future[JsonNode] {.gcsafe.}
```

Nerve uses drivers to power its clients. The driver recieves a completed JSON RPC request, and is responsible for sending that to the server and returning the JSON RPC response. The `nerve/drivers` module provides common drivers (such as an http driver), but user defined drivers can be used as well. The `nerve` module exports the `nerve/drivers` modules, so it is not necessary to import `drivers` separately.

## nerve/promises

The `promises` module provides target neutral (importable for both JS and native compiles) access to `Future[T]` types, as well as some helper functions. It is imported automatically when the `service` macro runs, and is accessible from any of the service procs or modifiers.

## nerve/websockets

Nerve has experimental support for Websockets as transport layer. It includes a websocket type built on top of treeform's [ws](https://github.com/treeform/ws) library on native clients, and the default built in browser implementation for JavaScript. Checkout Nerve's test suites for usage of the provided websocket driver and message callbacks.

# Configuration

The default behavior of the `service` macro is to produce both client and server code, but Nerve provides several options to configure this. The `nerve` module contains a `setDefaultConfig` macro that change the default behvior to produce either a server or a client. The `setDefaultConfig` macro takes a `ServiceConfigKind`: an enum that describes the different config options. The default can also be changed by defining the symbol `nerveClient` or `nerveServer` with the `-d` nim compiler flag. The final and most granular method of configuration is the `configureNerve` macro. The `configureNerve` macro takes a table of service identifiers to `ServiceConfigKind`. Important note: `configureNerve` and `setDefaultConfig` must run before the service module to correctly instantiates it. This means the macro call must run before the import of the service module.

```nim
setDefaultConfig(sckServer)
configureNerve({
    GrettingService: sckClient,
    FileService: sckServer
})
```

# Errors

Errors in RPC calls are propogated to the client. The client code will throw an `RpcError` with information from the error thrown on the server. If the server responds with a non-200 error code, the client throws an `InvalidResponseError`. The server throws errors for incorrect requests, per the JSON-RPC spec.

# Gotchas

Nerve trys to be as low friction as possible. However there are a couple edges to watch for.

1) Procedures under the same RPC server must have different names. No static method dispatch is possible.
2) Generic procs are also not possible.
3) The `service` macro doesn't mesh well with the Nim's `async` macro. See the section on promises for work arounds and more information.
