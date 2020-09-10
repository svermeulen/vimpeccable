local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local FileLogStream
do
  local _class_0
  local _base_0 = {
    initialize = function(self, minLogLevel, logPath)
      logPath = vim.fn.expand(logPath)
      self._minLogLevel = minLogLevel
      assert.that(self._minLogLevel)
      local file = io.open(logPath, "a")
      assert.that(file, "Could not open log file '" .. tostring(logPath) .. "'")
      file:setvbuf("line")
      self._fileStream = file
      vim.cmd([[augroup vimpFileLogStream]])
      vim.cmd([[au!]])
      vim.cmd([[au VimLeavePre * lua _vimp._fileLogStream:dispose()]])
      vim.cmd([[augroup END]])
      self._fileStream:write("Log file initialized\n")
      return self._fileStream:flush()
    end,
    dispose = function(self)
      self._fileStream:write("Closing log file!\n")
      self._fileStream:flush()
      return self._fileStream:close()
    end,
    log = function(self, message, level)
      if level >= self._minLogLevel then
        return self._fileStream:write(tostring(log.levels.strings[level]) .. "\t" .. tostring(message) .. "\n")
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self._fileStream = nil
    end,
    __base = _base_0,
    __name = "FileLogStream"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  FileLogStream = _class_0
  return _class_0
end
