
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys = '<space>t7<f4>'
TestKeys2 = ',<space>t9<f5>'

class Tester
  test_key_map: =>
    vimp.nnoremap { 'repeatable' }, TestKeys, 'dlldl'
    helpers.set_lines({"foo bar"})
    helpers.input("0w")
    helpers.rinput(TestKeys)
    assert.is_equal(helpers.get_line!, 'foo a')
    helpers.input("0")
    helpers.rinput('.')
    assert.is_equal(helpers.get_line!, 'o a')

  test_key_map_recursive: =>
    vimp.nnoremap TestKeys2, 'dlldl'
    vimp.nmap { 'repeatable' }, TestKeys, TestKeys2
    helpers.set_lines({"foo bar"})
    helpers.input("0w")
    helpers.rinput(TestKeys)
    assert.is_equal(helpers.get_line!, 'foo a')
    helpers.input("0")
    helpers.rinput('.')
    assert.is_equal(helpers.get_line!, 'o a')

  test_wrong_mode: =>
    assert.throws "currently only supported", ->
      vimp.inoremap { 'repeatable' }, TestKeys, 'foo'

  test_lua_func: =>
    vimp.nnoremap { 'repeatable' }, TestKeys, ->
      vim.cmd('normal! dlldl')
    helpers.set_lines({"foo bar"})
    helpers.input("0w")
    helpers.rinput(TestKeys)
    assert.is_equal(helpers.get_line!, 'foo a')
    helpers.input("0")
    helpers.rinput('.')
    assert.is_equal(helpers.get_line!, 'o a')

  test_lua_func_expr: =>
    assert.throws "currently not supported", ->
      vimp.nnoremap {'repeatable', 'expr'}, TestKeys, -> 'dlldl'
