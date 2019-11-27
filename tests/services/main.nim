import tables
import nerve

type
  Content* = ref object
    data*: string
    id*: int
  Node* = ref object
    content*: Content
  NodeContainer* = ref object
    children*: seq[Node]

service MainService, "/api/main":
  proc helloWorld(): Future[string] = futureWrap("Hello world")

  proc hello(name = "World"): Future[string] = futureWrap("Hello " & name)

  proc greet(greeting = "Hello", name = "World" ): Future[string] =
    futureWrap(greeting & " " & name)
  
  proc add(x, y = 0): Future[int] = futureWrap(x + y)

  proc run(): Future[void] = voidFuture()

  proc newNode(data: string, id: int): Future[Node] = futureWrap(
    Node(
      content: Content(data: data, id: id),
    ))

  proc newLeaf(content: Content): Future[Node] =
    futureWrap(
      Node(
        content: content,
    ))

  proc newBranch(children: seq[Node]): Future[NodeContainer] = futureWrap(
    NodeContainer(
      children: children
    ))

  proc hashByContent(nodes: seq[Node]): Future[Table[string, Node]] =
    var rv = initTable[string, Node]()
    for node in nodes:
      rv[node.content.data] = node
    result = futureWrap(rv)
