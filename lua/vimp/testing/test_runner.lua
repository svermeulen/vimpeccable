require('vimp')
local string_util = require('vimp.util.string')
local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local util = require("vimp.util.util")
local TestRunner
do
  local _class_0
  local _base_0 = {
    _get_plugin_root_path = function(self)
      local matches
      do
        local _accum_0 = { }
        local _len_0 = 1
        for x in string.gmatch(vim.api.nvim_eval('&rtp'), "([^,]+)") do
          if string_util.ends_with(x, '/vimpeccable') then
            _accum_0[_len_0] = x
            _len_0 = _len_0 + 1
          end
        end
        matches = _accum_0
      end
      assert.that(#matches == 1)
      return matches[1]
    end,
    _run_test_func = function(self, func)
      local start_tab = vim.api.nvim_get_current_tabpage()
      vim.cmd('normal! ' .. util.replace_special_chars("<c-w>v<c-w>T"))
      local test_tab = vim.api.nvim_get_current_tabpage()
      local buffer_handle = vim.api.nvim_create_buf(true, false)
      vim.cmd("b " .. tostring(buffer_handle))
      vimp.map_error_handling_strategy = vimp.map_error_handling_strategies.none
      assert.that(vim.o.hidden, "Must set hidden property to run tests")
      local action
      action = function()
        func()
        return vimp.unmap_all()
      end
      local success, ret_value = xpcall(action, debug.traceback)
      vim.api.nvim_set_current_tabpage(test_tab)
      vim.cmd('tabclose!')
      if vim.api.nvim_buf_is_loaded(buffer_handle) then
        vim.cmd("bd! " .. tostring(buffer_handle))
      end
      vim.api.nvim_set_current_tabpage(start_tab)
      pcall(vimp.unmap_all)
      if not success then
        return error(ret_value, 2)
      end
    end,
    _init_logging = function(self)
      vimp.print_min_log_level = 'info'
    end,
    run_test_file = function(self, file_path)
      self:_init_logging()
      local success_count = self:_run_test_file(file_path)
      return log.info(tostring(success_count) .. " tests completed successfully")
    end,
    _run_test_file = function(self, file_path)
      local test_class = dofile(file_path)
      local tester = test_class()
      log.info("Executing tests for file " .. tostring(file_path) .. "...")
      local success_count = 0
      for methodName, func in pairs(getmetatable(tester)) do
        if string_util.startsWith(methodName, 'test') then
          log.info("Executing test '" .. tostring(methodName) .. "' from file '" .. tostring(file_path) .. "'...")
          self:_run_test_func(function()
            return func(tester)
          end)
          success_count = success_count + 1
        end
      end
      return success_count
    end,
    run_test_method = function(self, file_path, test_name)
      self:_init_logging()
      local test_class = dofile(file_path)
      local tester = test_class()
      log.info("Executing test '" .. tostring(test_name) .. "' from file '" .. tostring(file_path) .. "'...")
      self:_run_test_func(function()
        return tester[test_name](tester)
      end)
      return log.info("Test " .. tostring(test_name) .. " completed successfully")
    end,
    run_all_tests = function(self)
      self:_init_logging()
      local test_root = tostring(self:_get_plugin_root_path()) .. "/lua"
      local success_count = 0
      local _list_0 = vim.fn.globpath(test_root, '**/test_*.lua', 0, 1)
      for _index_0 = 1, #_list_0 do
        local test_file = _list_0[_index_0]
        success_count = success_count + self:_run_test_file(test_file)
      end
      return log.info(tostring(success_count) .. " tests completed successfully")
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
