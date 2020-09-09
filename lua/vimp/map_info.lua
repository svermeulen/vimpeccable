local assert = require("vimp.util.assert")
local MapInfo
do
  local _class_0
  local _base_0 = {
    _getActualRhs = function(self)
      if type(self.rhs) == 'string' then
        return self.rhs
      end
      assert.that(type(self.rhs) == 'function')
      if self.options.expr then
        return "luaeval('_vimp:_executeMap(" .. tostring(self.id) .. ")')"
      end
      assert.that(self.mode ~= 'c', "Lua function maps for command mode are not currently supported.  Can you use an <expr> lua function instead?")
      assert.that(self.mode ~= 't', "Lua function maps for terminal mode are not currently supported.  Can you use an <expr> lua function instead?")
      assert.that(self.options.noremap, "Cannot use recursive mapping with lua function")
      if self.mode == 'i' then
        return "<c-o>:lua _vimp:_executeMap(" .. tostring(self.id) .. ")<cr>"
      end
      if self.mode == 's' then
        return "<esc>:lua _vimp:_executeMap(" .. tostring(self.id) .. ")<cr>"
      end
      return ":<c-u>lua _vimp:_executeMap(" .. tostring(self.id) .. ")<cr>"
    end,
    getRhsDisplayText = function(self)
      if type(self.rhs) == 'string' then
        return self.rhs
      end
      assert.that(type(self.rhs) == 'function')
      return "<lua function " .. tostring(self.id) .. ">"
    end,
    addToVim = function(self)
      local actualRhs = self:_getActualRhs()
      if self.bufferHandle ~= nil then
        return vim.api.nvim_buf_set_keymap(self.bufferHandle, self.mode, self.expandedLhs, actualRhs, self.options)
      else
        return vim.api.nvim_set_keymap(self.mode, self.expandedLhs, actualRhs, self.options)
      end
    end,
    removeFromVim = function(self)
      if self.bufferHandle ~= nil then
        return vim.api.nvim_buf_del_keymap(self.bufferHandle, self.mode, self.expandedLhs)
      else
        return vim.api.nvim_del_keymap(self.mode, self.expandedLhs)
      end
    end,
    toString = function(self)
      return "'" .. tostring(self.lhs) .. "' -> '" .. tostring(self:getRhsDisplayText()) .. "'"
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, id, mode, options, extraOptions, lhs, expandedLhs, rawLhs, rhs, bufferHandle)
      self.id = id
      self.lhs = lhs
      self.expandedLhs = expandedLhs
      self.rawLhs = rawLhs
      self.rhs = rhs
      self.options = options
      self.extraOptions = extraOptions
      self.mode = mode
      self.bufferHandle = bufferHandle
    end,
    __base = _base_0,
    __name = "MapInfo"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  MapInfo = _class_0
  return _class_0
end
