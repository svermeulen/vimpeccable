local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local CommandMapInfo
do
  local _class_0
  local _base_0 = {
    remove_from_vim = function(self)
      return vim.api.nvim_command("delcommand " .. tostring(self.name))
    end,
    _get_n_args_from_handler = function(self)
      local handler_info = debug.getinfo(self.handler)
      if handler_info.isvararg then
        return '*'
      end
      if handler_info.nparams == 1 then
        return '1'
      end
      if handler_info.nparams == 0 then
        return '0'
      end
      return '*'
    end,
    _get_options_string = function(self)
      local stringified_options = { }
      if self.options.complete ~= nil then
        assert.that(type(self.options.complete) == 'string', "Expected type 'string' for option 'complete' but instead found '" .. tostring(type(self.options.complete)) .. "'")
        table.insert(stringified_options, "-complete=" .. tostring(self.options.complete))
      end
      return table.concat(stringified_options, ' ')
    end,
    _create_command_str = function(self)
      local nargs = self:_get_n_args_from_handler()
      local options_string = self:_get_options_string()
      if nargs == '0' then
        return "command -nargs=0 " .. tostring(options_string) .. " " .. tostring(self.name) .. " lua _vimp:_executeCommandMap(" .. tostring(self.id) .. ", {})"
      end
      if nargs == '1' then
        return "command -nargs=1 " .. tostring(options_string) .. " " .. tostring(self.name) .. " call luaeval(\"_vimp:_executeCommandMap(" .. tostring(self.id) .. ", {_A})\", <q-args>)"
      end
      return "command -nargs=* " .. tostring(options_string) .. " " .. tostring(self.name) .. " call luaeval(\"_vimp:_executeCommandMap(" .. tostring(self.id) .. ", _A)\", [<f-args>])"
    end,
    add_to_vim = function(self)
      local command_str = self:_create_command_str()
      return vim.api.nvim_command(command_str)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, id, handler, name, options)
      self.id = id
      self.handler = handler
      self.name = name
      self.options = options
    end,
    __base = _base_0,
    __name = "CommandMapInfo"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  CommandMapInfo = _class_0
  return _class_0
end
