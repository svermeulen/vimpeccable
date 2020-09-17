local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local FileLogStream
do
  local _class_0
  local _base_0 = {
    initialize = function(self, min_log_level, log_path)
      log_path = vim.fn.expand(log_path)
      self._min_log_level = min_log_level
      assert.that(self._min_log_level)
      local file = io.open(log_path, "a")
      assert.that(file, "Could not open log file '" .. tostring(log_path) .. "'")
      file:setvbuf("line")
      self._file_stream = file
      vim.api.nvim_command([[augroup vimpFileLogStream]])
      vim.api.nvim_command([[au!]])
      vim.api.nvim_command([[au VimLeavePre * lua _vimp._file_log_stream:dispose()]])
      vim.api.nvim_command([[augroup END]])
      self._file_stream:write("Log file initialized\n")
      return self._file_stream:flush()
    end,
    dispose = function(self)
      self._file_stream:write("Closing log file!\n")
      self._file_stream:flush()
      return self._file_stream:close()
    end,
    log = function(self, message, level)
      if level >= self._min_log_level then
        return self._file_stream:write(tostring(log.levels.strings[level]) .. "\t" .. tostring(message) .. "\n")
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self._file_stream = nil
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
