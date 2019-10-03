import nerve, nerve/web

type
  Content* = ref object
    data*: string
    id*: int
  Node* = ref object
    content*: Content
  NodeContainer* = ref object
    children*: seq[Node]

service MainService, "/api/person":
  proc helloWorld(): Future[string] = fwrap("Hello world")

  proc hello(name = "World"): Future[string] = fwrap("Hello " & name)

  proc greet(greeting = "Hello", name = "World" ): Future[string] =
    fwrap(greeting & " " & name)
  
  proc add(x, y = 0): Future[int] = fwrap(x + y)

  proc newNode(data: string, id: int): Future[Node] = fwrap(
    Node(
      content: Content(data: data, id: id),
    ))

  proc newLeaf(content: Content): Future[Node] =
    fwrap(
      Node(
        content: content,
    ))

  proc newBranch(children: seq[Node]): Future[NodeContainer] = fwrap(
    NodeContainer(
      children: children
    ))
