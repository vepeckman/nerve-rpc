import unittest

import current

block:
  test "sanity":
    rpc:
      proc hello(name: string): string = "Hello " & name
    check(handler(%* {"method": "hello", "params": {"name": "world"}}).to(string) == "Hello world")

  test "Default params":
    rpc:
      proc hello(name: string, punc = "!"): string = "Hello " & name & punc
    check(handler(%* {"method": "hello", "params": {"name": "world"}}).to(string) == "Hello world!")
    check(handler(%* {"method": "hello", "params": {"name": "world", "punc": "."}}).to(string) == "Hello world.")

test "Dispatch":
  rpc:
    proc add(x, y: int): int = x + y
    proc sub(x, y = 0): int = x - y
  check(handler(%* {"method": "add", "params": {"x": 1, "y": 1}}).to(int) == 2)
  check(handler(%* {"method": "sub", "params": {"x": 1, "y": 0}}).to(int) == 1)
