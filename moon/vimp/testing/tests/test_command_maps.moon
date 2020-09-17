
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

class Tester
  test_zero_args: =>
    received = false
    vimp.map_command "Foo", ->
      received = true
    assert.that(not received)
    vim.cmd("Foo")
    assert.that(received)

  test_one_args: =>
    received = nil
    vimp.map_command "Foo", (val) ->
      received = val
    assert.that(received == nil)
    vim.cmd("Foo 5")
    assert.is_equal(received, '5')
    vim.cmd("Foo foo bar qux")
    assert.is_equal(received, "foo bar qux")
    assert.throws "Argument required", ->
      vim.cmd("Foo")

  test_two_args: =>
    received1 = nil
    received2 = nil
    vimp.map_command "Foo", (val1, val2) ->
      received1 = val1
      received2 = val2
    assert.that(received2 == nil)
    assert.that(received1 == nil)
    vim.cmd("Foo 5")
    assert.is_equal(received1, '5')
    assert.is_equal(received2, nil)
    vim.cmd("Foo")
    assert.is_equal(received1, nil)
    assert.is_equal(received2, nil)
    vim.cmd("Foo first second")
    assert.is_equal(received1, 'first')
    assert.is_equal(received2, 'second')
    vim.cmd("Foo first second third")
    assert.is_equal(received1, 'first')
    assert.is_equal(received2, 'second')

  test_var_args: =>
    received = nil
    vimp.map_command "Foo", (...) ->
      received = {...}
    assert.that(received == nil)
    vim.cmd("Foo")
    assert.that(#received == 0)
    vim.cmd("Foo first")
    assert.that(#received == 1)
    assert.that(received[1] == "first")
    vim.cmd("Foo first second third")
    assert.that(#received == 3)
    helpers.assert_same_contents(received, {'first', 'second', 'third'})
