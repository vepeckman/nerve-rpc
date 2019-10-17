import unittest, tables
import nerve, nerve/promises
import ../services/main

proc runMainSuite*(
  mainClient: MainService.rpcType
  ) {.async.} =

  suite "Sanity":

    test "Hello":
      let msg = await mainClient.hello("Nic")
      check(msg == "Hello Nic")
      let helloWorld = await mainClient.hello()
      check(helloWorld == "Hello World")

  suite "Proc arguments":

    test "Multiple defaults (a = x, b = y)":
      let g1 = await mainClient.greet()
      let g2 = await mainClient.greet(name = "Nic")
      let g3 = await mainClient.greet("Yo")
      let g4 = await mainClient.greet("Goodday", "child")
      check(g1 == "Hello World")
      check(g2 == "Hello Nic")
      check(g3 == "Yo World")
      check(g4 == "Goodday child")

    test "Multiple defaults (a, b = x)":
      let x = await mainClient.add()
      let y = await mainClient.add(1)
      let z = await mainClient.add(2, 3)
      check(x == 0)
      check(y == 1)
      check(z == 5)

    test "No params":
      let msg = await mainClient.helloWorld()
      check(msg == "Hello world")

  suite "Objects":

    test "Receive object":
      let n = await mainClient.newNode("data", 1)
      check(n.content.data == "data")
      check(n.content.id == 1)

    test "Send and receive object":
      let content = Content(data: "info", id: 2)
      let n = await mainClient.newLeaf(content)
      check(n.content.data == "info")
      check(n.content.id == 2)

    test "Send seq":
      let content = Content(data: "info", id: 2)
      let n = Node(content: content)
      let nc = await mainClient.newBranch(@[n])
      check(nc.children.len == 1)
      check(nc.children[0].content.data == "info")

    test "Recieve table":
      let content = Content(data: "info", id: 2)
      let n = Node(content: content)
      let ntable = await mainClient.hashByContent(@[n])
      check(not isNil(ntable["info"]))

