import unittest
import asyncjs, jsffi

import current

test "sanity":
  rpc:
    proc hello(name: string): Future[string] = "Hello " & name
