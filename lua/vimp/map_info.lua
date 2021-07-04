local assert = require("vimp.util.assert")
local MapInfo
do
  local _class_0
  local _base_0 = {
    _get_actual_rhs = function(self)
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
    get_rhs_display_text = function(self)
      local result = None
      if type(self.rhs) == 'string' then
        result = self.rhs
      else
        assert.that(type(self.rhs) == 'function')
        result = "<lua function " .. tostring(self.id) .. ">"
      end
      return result
    end,
    add_to_vim = function(self)
      local actualRhs = self:_get_actual_rhs()
      if self.buffer_handle ~= nil then
        return vim.api.nvim_buf_set_keymap(self.buffer_handle, self.mode, self.expanded_lhs, actualRhs, self.options)
      else
        return vim.api.nvim_set_keymap(self.mode, self.expanded_lhs, actualRhs, self.options)
      end
    end,
    remove_from_vim = function(self)
      if self.buffer_handle ~= nil then
        return vim.api.nvim_buf_del_keymap(self.buffer_handle, self.mode, self.expanded_lhs)
      else
        return vim.api.nvim_del_keymap(self.mode, self.expanded_lhs)
      end
    end,
    to_string = function(self)
      local result = "'" .. tostring(self.lhs) .. "' -> '" .. tostring(self:get_rhs_display_text()) .. "'"
      if self.context_info ~= nil then
        result = result .. (" with context: " .. tostring(self.context_info))
      end
      return result
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, id, mode, options, extra_options, lhs, expanded_lhs, raw_lhs, rhs, buffer_handle, context_info)
      self.id = id
      self.lhs = lhs
      self.expanded_lhs = expanded_lhs
      self.raw_lhs = raw_lhs
      self.rhs = rhs
      self.options = options
      self.extra_options = extra_options
      self.mode = mode
      self.buffer_handle = buffer_handle
      self.context_info = context_info
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
