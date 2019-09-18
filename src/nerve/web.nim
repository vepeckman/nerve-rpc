import json
export json
when not defined(js):

  type wstring* = string

else:
  import jsffi

  type wstring* = cstring

  export jsffi
