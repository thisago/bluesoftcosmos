import std/unittest
import bluesoftcosmos

suite "bluesoftcosmos":
  test "Can say":
    const msg = "Hello from bluesoftcosmos test"
    check msg == say msg
