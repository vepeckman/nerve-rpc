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
        await req.respond(Http200, readFile("examples/oneFile/nimcache/main.js"), headers)
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
