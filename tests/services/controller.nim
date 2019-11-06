import nerve
import view, model

service ControllerService, "/api/controller":

  inject:
    var viewClient: ViewService.rpcType
    var modelServer: ModelService.rpcType

  proc update(data: string): Future[string] =
    modelServer.updateData(data)
      .then(proc (data: string): Future[void] = viewClient.render(data))
      .then(proc (): string = data)
