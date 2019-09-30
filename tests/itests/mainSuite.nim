import unittest
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

    test "Add":
      let x = await mainClient.add()
      let y = await mainClient.add(1)
      let z = await mainClient.add(2, 3)
      check(x == 0)
      check(y == 1)
      check(z == 5)

    test "Person":
      let person = await mainClient.newPerson("Nic", 24)
      check(person.name == "Nic")

    test "Parent":
      let person = await mainClient.newPerson("Alex", 32)
      let child = await mainClient.newPerson("James", 4)
      let parent = await mainClient.newParent(person, child)
      check(parent.self.name == "Alex")
      check(parent.children[0].name == "James")

  suite "Proc arguments":

    test "Multiple defaults":
      let g1 = await mainClient.greet()
      let g2 = await mainClient.greet(name = "Nic")
      let g3 = await mainClient.greet("Yo")
      let g4 = await mainClient.greet("Goodday", "child")
      check(g1 == "Hello World")
      check(g2 == "Hello Nic")
      check(g3 == "Yo World")
      check(g4 == "Goodday child")

    test "No params":
      let msg = await mainClient.helloWorld()
      check(msg == "Hello world")
