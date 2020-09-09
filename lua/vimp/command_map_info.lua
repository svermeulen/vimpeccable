local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local CommandMapInfo
do
  local _class_0
  local _base_0 = {
    removeFromVim = function(self)
      return vim.cmd("delcommand " .. tostring(self.name))
    end,
    _getNArgsFromHandler = function(self)
      local handlerInfo = debug.getinfo(self.handler)
      if handlerInfo.isvararg then
        return '*'
      end
      if handlerInfo.nparams == 1 then
        return '1'
      end
      if handlerInfo.nparams == 0 then
        return '0'
      end
      return '*'
    end,
    _createCommandStr = function(self)
      local nargs = self:_getNArgsFromHandler()
      if nargs == '0' then
        return "command -nargs=0 " .. tostring(self.name) .. " lua _vimp:_executeCommandMap(" .. tostring(self.id) .. ", {})"
      end
      if nargs == '1' then
        return "command -nargs=1 " .. tostring(self.name) .. " call luaeval(\"_vimp:_executeCommandMap(" .. tostring(self.id) .. ", {_A})\", <q-args>)"
      end
      return "command -nargs=* " .. tostring(self.name) .. " call luaeval(\"_vimp:_executeCommandMap(" .. tostring(self.id) .. ", _A)\", [<f-args>])"
    end,
    addToVim = function(self)
      local commandStr = self:_createCommandStr()
      return vim.cmd(commandStr)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, id, handler, name)
      self.id = id
      self.handler = handler
      self.name = name
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
