require('vimp')
local stringUtil = require('vimp.util.string')
local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local util = require("vimp.util.util")
local TestRunner
do
  local _class_0
  local _base_0 = {
    _getPluginRootPath = function(self)
      local matches
      do
        local _accum_0 = { }
        local _len_0 = 1
        for x in string.gmatch(vim.api.nvim_eval('&rtp'), "([^,]+)") do
          if stringUtil.endsWith(x, '/vimpeccable') then
            _accum_0[_len_0] = x
            _len_0 = _len_0 + 1
          end
        end
        matches = _accum_0
      end
      assert.that(#matches == 1)
      return matches[1]
    end,
    _runTestFunc = function(self, func)
      local startTab = vim.api.nvim_get_current_tabpage()
      vim.cmd('normal! ' .. util.replaceSpecialChars("<c-w>v<c-w>T"))
      local testTab = vim.api.nvim_get_current_tabpage()
      local bufferHandle = vim.api.nvim_create_buf(true, false)
      vim.cmd("b " .. tostring(bufferHandle))
      vimp.mapErrorHandlingStrategy = vimp.mapErrorHandlingStrategies.none
      assert.that(vim.o.hidden, "Must set hidden property to run tests")
      local action
      action = function()
        func()
        return vimp.unmapAll()
      end
      local success, retValue = xpcall(action, debug.traceback)
      vim.api.nvim_set_current_tabpage(testTab)
      vim.cmd('tabclose!')
      if vim.api.nvim_buf_is_loaded(bufferHandle) then
        vim.cmd("bd! " .. tostring(bufferHandle))
      end
      vim.api.nvim_set_current_tabpage(startTab)
      pcall(vimp.unmapAll)
      if not success then
        return error(retValue, 2)
      end
    end,
    _initLogging = function(self)
      vimp.printMinLogLevel = 'info'
    end,
    runTestFile = function(self, filePath)
      self:_initLogging()
      local successCount = self:_runTestFile(filePath)
      return log.info(tostring(successCount) .. " tests completed successfully")
    end,
    _runTestFile = function(self, filePath)
      local testClass = dofile(filePath)
      local tester = testClass()
      log.info("Executing tests for file " .. tostring(filePath) .. "...")
      local successCount = 0
      for methodName, func in pairs(getmetatable(tester)) do
        if stringUtil.startsWith(methodName, 'test') then
          log.info("Executing test '" .. tostring(methodName) .. "' from file '" .. tostring(filePath) .. "'...")
          self:_runTestFunc(function()
            return func(tester)
          end)
          successCount = successCount + 1
        end
      end
      return successCount
    end,
    runTestMethod = function(self, filePath, testName)
      self:_initLogging()
      local testClass = dofile(filePath)
      local tester = testClass()
      log.info("Executing test '" .. tostring(testName) .. "' from file '" .. tostring(filePath) .. "'...")
      self:_runTestFunc(function()
        return tester[testName](tester)
      end)
      return log.info("Test " .. tostring(testName) .. " completed successfully")
    end,
    runAllTests = function(self)
      self:_initLogging()
      local testRoot = tostring(self:_getPluginRootPath()) .. "/lua"
      local successCount = 0
      local _list_0 = vim.fn.globpath(testRoot, '**/test_*.lua', 0, 1)
      for _index_0 = 1, #_list_0 do
        local testFile = _list_0[_index_0]
        successCount = successCount + self:_runTestFile(testFile)
      end
      return log.info(tostring(successCount) .. " tests completed successfully")
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "TestRunner"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  TestRunner = _class_0
  return _class_0
end
