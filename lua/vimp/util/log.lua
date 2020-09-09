local LogLevels = {
  debug = 1,
  info = 2,
  warning = 3,
  error = 4,
  all = {
    1,
    2,
    3,
    4
  },
  strings = {
    "debug",
    "info",
    "warning",
    "error"
  }
}
local PrintLogStream
do
  local _class_0
  local _base_0 = {
    log = function(self, message, level)
      if level >= self.minLogLevel then
        return vim.api.nvim_out_write("[vimp] " .. tostring(LogLevels.strings[level]) .. ": " .. tostring(message) .. "\n")
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self.minLogLevel = LogLevels.warning
    end,
    __base = _base_0,
    __name = "PrintLogStream"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  PrintLogStream = _class_0
end
local log
do
  local _class_0
  local _base_0 = {
    levels = LogLevels,
    streams = {
      PrintLogStream()
    },
    log = function(message, level)
      if message == nil then
        message = "nil"
      elseif type(message) ~= 'string' then
        message = tostring(message)
      end
      local _list_0 = log.streams
      for _index_0 = 1, #_list_0 do
        local stream = _list_0[_index_0]
        stream:log(message, level)
      end
    end,
    debug = function(message)
      return log.log(message, LogLevels.debug)
    end,
    info = function(message)
      return log.log(message, LogLevels.info)
    end,
    warning = function(message)
      return log.log(message, LogLevels.warning)
    end,
    error = function(message)
      return log.log(message, LogLevels.error)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "log"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  log = _class_0
  return _class_0
end
