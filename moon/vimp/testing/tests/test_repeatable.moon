
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys = '<space>t7<f4>'
TestKeys2 = ',<space>t9<f5>'

class Tester
  testKeyMap: =>
    vimp.nnoremap { 'repeatable' }, TestKeys, 'dlldl'
    helpers.setLines({"foo bar"})
    helpers.input("0w")
    helpers.rinput(TestKeys)
    assert.isEqual(helpers.getLine!, 'foo a')
    helpers.input("0")
    helpers.rinput('.')
    assert.isEqual(helpers.getLine!, 'o a')

  testKeyMapRecursive: =>
    vimp.nnoremap TestKeys2, 'dlldl'
    vimp.nmap { 'repeatable' }, TestKeys, TestKeys2
    helpers.setLines({"foo bar"})
    helpers.input("0w")
    helpers.rinput(TestKeys)
    assert.isEqual(helpers.getLine!, 'foo a')
    helpers.input("0")
    helpers.rinput('.')
    assert.isEqual(helpers.getLine!, 'o a')

  testWrongMode: =>
    assert.throws "currently only supported", ->
      vimp.inoremap { 'repeatable' }, TestKeys, 'foo'

  testLuaFunc: =>
    vimp.nnoremap { 'repeatable' }, TestKeys, ->
      vim.cmd('normal! dlldl')
    helpers.setLines({"foo bar"})
    helpers.input("0w")
    helpers.rinput(TestKeys)
    assert.isEqual(helpers.getLine!, 'foo a')
    helpers.input("0")
    helpers.rinput('.')
    assert.isEqual(helpers.getLine!, 'o a')

  testLuaFuncExpr: =>
    assert.throws "currently not supported", ->
      vimp.nnoremap {'repeatable', 'expr'}, TestKeys, -> 'dlldl'
