import unittest
import nerve, nerve/promises
import ../services/[view, model, controller]


proc runMvcClientSuite*(
  viewServer: ViewService.rpcType,
  controllerClient: ControllerService.rpcType,
  viewData: ViewData) {.async.} =
  suite "MVC Client":

    test "Calling controller updates view":
      check(viewData.html == "hello world")
      discard await controllerClient.update("another page")
      check(viewData.html == "another page")
      discard await controllerClient.update("yet another page")
      check(viewData.html == "yet another page")
