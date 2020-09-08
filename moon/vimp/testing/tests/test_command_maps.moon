
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

class Tester
  testZeroArgs: =>
    received = false
    vimp.mapCommand "Foo", ->
      received = true
    assert.that(not received)
    vim.cmd("Foo")
    assert.that(received)

  testOneArgs: =>
    received = nil
    vimp.mapCommand "Foo", (val) ->
      received = val
    assert.that(received == nil)
    vim.cmd("Foo 5")
    assert.isEqual(received, '5')
    vim.cmd("Foo foo bar qux")
    assert.isEqual(received, "foo bar qux")
    assert.throws "Argument required", ->
      vim.cmd("Foo")

  testTwoArgs: =>
    received1 = nil
    received2 = nil
    vimp.mapCommand "Foo", (val1, val2) ->
      received1 = val1
      received2 = val2
    assert.that(received2 == nil)
    assert.that(received1 == nil)
    vim.cmd("Foo 5")
    assert.isEqual(received1, '5')
    assert.isEqual(received2, nil)
    vim.cmd("Foo")
    assert.isEqual(received1, nil)
    assert.isEqual(received2, nil)
    vim.cmd("Foo first second")
    assert.isEqual(received1, 'first')
    assert.isEqual(received2, 'second')
    vim.cmd("Foo first second third")
    assert.isEqual(received1, 'first')
    assert.isEqual(received2, 'second')

  testVarArgs: =>
    received = nil
    vimp.mapCommand "Foo", (...) ->
      received = {...}
    assert.that(received == nil)
    vim.cmd("Foo")
    assert.that(#received == 0)
    vim.cmd("Foo first")
    assert.that(#received == 1)
    assert.that(received[1] == "first")
    vim.cmd("Foo first second third")
    assert.that(#received == 3)
    helpers.assertSameContents(received, {'first', 'second', 'third'})
