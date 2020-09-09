
require('vimp')
stringUtil = require('vimp.util.string')
assert = require("vimp.util.assert")
log = require("vimp.util.log")
util = require("vimp.util.util")

class TestRunner
  _getPluginRootPath: =>
    matches = [x for x in string.gmatch(vim.api.nvim_eval('&rtp'), "([^,]+)") when stringUtil.endsWith(x, '/vimpeccable')]
    assert.that(#matches == 1)
    return matches[1]

  _runTestFunc: (func) =>
    startTab = vim.api.nvim_get_current_tabpage()
    vim.cmd('normal! ' .. util.replaceSpecialChars("<c-w>v<c-w>T"))
    testTab = vim.api.nvim_get_current_tabpage()
    bufferHandle = vim.api.nvim_create_buf(true, false)
    vim.cmd("b #{bufferHandle}")
    -- Always throw exceptions during testing
    vimp.mapErrorHandlingStrategy = vimp.mapErrorHandlingStrategies.none
    -- log.enableFileLogging("debug", "~/Temp/vimpeccable.log")

    action = ->
      func!
      vimp.unmapAll!

    success, retValue = xpcall(action, debug.traceback)

    vim.api.nvim_set_current_tabpage(testTab)
    vim.cmd('tabclose')
    vim.cmd("bd! #{bufferHandle}")
    vim.api.nvim_set_current_tabpage(startTab)

    -- Try this in case the error occurred during func!
    -- And just ignore any errors that occur
    -- We don't _just_ do this because we want the error from
    -- unmapAll to propagate if it gets that far
    -- This is nice because it will remove the maps from vim
    -- so we might not need to do a full restart to avoid getting
    -- errors if we run the tests again
    pcall(vimp.unmapAll)

    if not success
      error(retValue, 2)

  runTestFile: (filePath) =>
    successCount = @\_runTestFile(filePath)
    log.info("#{successCount} tests completed successfully")

  _runTestFile: (filePath) =>
    testClass = dofile(filePath)
    tester = testClass!
    log.debug("Executing tests for file #{filePath}...")

    successCount = 0

    for methodName,func in pairs(getmetatable(tester))
      if stringUtil.startsWith(methodName, 'test')
        log.info("Executing test '#{methodName}' from file '#{filePath}'...")
        @\_runTestFunc -> func(tester)
        successCount += 1

    return successCount

  runTestMethod: (filePath, testName) =>
    testClass = dofile(filePath)
    tester = testClass!
    log.info("Executing test '#{testName}' from file '#{filePath}'...")
    @\_runTestFunc ->
      tester[testName](tester)
    log.info("Test #{testName} completed successfully")

  runAllTests: =>
    testRoot = "#{@\_getPluginRootPath!}/lua"

    successCount = 0
    for testFile in *vim.fn.globpath(testRoot, '**/test_*.lua', 0, 1)
      successCount += @\_runTestFile(testFile)

    log.info("#{successCount} tests completed successfully")
