import jsffi, json

type Person = ref object
  name: string
  age: int

{.emit: """
let jsPerson = {
  name: "Nic",
  age: 23
};"""
.}

var jsPerson {. importc, nodecl .}: JsObject
proc main(data: JsObject) =
  var person = data.to(Person)
  echo person.name

main(jsPerson)
