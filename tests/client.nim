import asyncjs, unittest
import api

proc main() {.async.} =
  suite "Sanity":

    test "Hello":
      let msg = await example.hello("Nic")
      check(msg == "Hello Nic")
      let helloWorld = await example.hello()
      check(helloWorld == "Hello World")

    test "Add":
      let x = await example.add()
      let y = await example.add(1)
      let z = await example.add(2, 3)
      check(x == 0)
      check(y == 1)
      check(z == 5)

    test "Person":
      let person = await example.newPerson("Nic", 24)
      check(person.name == "Nic")

    test "Parent":
      let person = await example.newPerson("Alex", 32)
      let child = await example.newPerson("James", 4)
      let parent = await example.newParent(person, child)
      check(parent.self.name == "Alex")
      check(parent.children[0].name == "James")


discard main()
