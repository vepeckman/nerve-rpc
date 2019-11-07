import macros, tables, strutils, types

var default {. compiletime .} = sckFull

var configTable {. compiletime .} = initTable[string, ServiceConfigKind]()

proc mergeConfigObject*(config: NimNode) =
  assert(config.kind == nnkTableConstr, "Configuration object must be a table")
  for serviceConfig in config.children:
    configTable.add(serviceConfig[0].strVal(), parseEnum[ServiceConfigKind](serviceConfig[1].strVal()))

proc getConfig*(service: string): ServiceConfigKind =
  if configTable.hasKey(service): configTable[service]
  elif defined(nerveServer): sckServer
  elif defined(nerveClient): sckClient
  else: default

proc setDefaultConfig*(config: ServiceConfigKind) =
  default = config
