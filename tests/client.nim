import asyncjs, unittest
import personService, greetingService, fileService

proc main() {.async.} =
  suite "Sanity":

    test "Hello":
      let msg = await PersonService.hello("Nic")
      check(msg == "Hello Nic")
      let helloWorld = await PersonService.hello()
      check(helloWorld == "Hello World")

    test "Add":
      let x = await PersonService.add()
      let y = await PersonService.add(1)
      let z = await PersonService.add(2, 3)
      check(x == 0)
      check(y == 1)
      check(z == 5)

    test "Person":
      let person = await PersonService.newPerson("Nic", 24)
      check(person.name == "Nic")

    test "Parent":
      let person = await PersonService.newPerson("Alex", 32)
      let child = await PersonService.newPerson("James", 4)
      let parent = await PersonService.newParent(person, child)
      check(parent.self.name == "Alex")
      check(parent.children[0].name == "James")

    test "Error":
      discard await FileService.saveFile("missing.txt", "failure")

  suite "Proc arguments":

    test "Multiple defaults":
      let g1 = await GreetingService.greet()
      let g2 = await GreetingService.greet(name = "Nic")
      let g3 = await GreetingService.greet("Yo")
      let g4 = await GreetingService.greet("Goodday", "child")
      check(g1 == "Hello World")
      check(g2 == "Hello Nic")
      check(g3 == "Yo World")
      check(g4 == "Goodday child")

    test "No params":
      let msg = await PersonService.helloWorld()
      check(msg == "Hello world")


discard main()
