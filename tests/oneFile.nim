import nerve

configureNerve({
  OneFile: sckServer
})

service OneFile:

  serverImports(base64)

  clientImports(random)

  proc hello(x: int): Future[string] = fwrap(encode($ x))

  server:
    echo "Making server"

    let server = OneFile.newServer()

  client:
    echo "Making client"

    let client = OneFile.newHttpClient()
