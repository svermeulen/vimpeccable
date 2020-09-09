local assert = require("vimp.util.assert")
local stringUtil = require("vimp.util.string")
local Helpers
do
  local _class_0
  local _base_0 = {
    rinput = function(keys)
      local rawKeys = vim.api.nvim_replace_termcodes(keys, true, false, true)
      return vim.api.nvim_feedkeys(rawKeys, 'mx', false)
    end,
    input = function(keys)
      local rawKeys = vim.api.nvim_replace_termcodes(keys, true, false, true)
      return vim.api.nvim_feedkeys(rawKeys, 'nx', false)
    end,
    getCursorColumn = function()
      local pos = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())
      return pos[2]
    end,
    getCursorCharacter = function()
      return stringUtil.charAt(Helpers.getLine(), Helpers.getCursorColumn() + 1)
    end,
    setLines = function(lines)
      local bufferHandle = vim.api.nvim_get_current_buf()
      return vim.api.nvim_buf_set_lines(bufferHandle, 0, -1, false, lines)
    end,
    getLine = function()
      return vim.api.nvim_get_current_line()
    end,
    unlet = function(name)
      if vim.g[name] ~= nil then
        vim.g[name] = nil
      end
    end,
    hasSameContents = function(list1, list2)
      if #list1 ~= #list2 then
        return false
      end
      local map1
      do
        local _tbl_0 = { }
        for _index_0 = 1, #list1 do
          local x = list1[_index_0]
          _tbl_0[x] = true
        end
        map1 = _tbl_0
      end
      for _index_0 = 1, #list2 do
        local item = list2[_index_0]
        if map1[item] == nil then
          return false
        end
      end
      return true
    end,
    assertSameContents = function(list1, list2)
      return assert.that(Helpers.hasSameContents(list1, list2), "Expected '" .. tostring(vim.inspect(list1)) .. "' to equal '" .. tostring(vim.inspect(list2)) .. "'")
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Helpers"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Helpers = _class_0
  return _class_0
end
