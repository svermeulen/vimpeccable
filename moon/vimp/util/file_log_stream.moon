
assert = require("vimp.util.assert")
log = require("vimp.util.log")

class FileLogStream
  new: =>
    @_fileStream = nil

  _convertLogLevelStringToLevel: (logLevelStr) =>
    for i=1,#log.levels.strings
      if logLevelStr == log.levels.strings[i]
        return i
    assert.that(false, "Invalid log level '#{logLevelStr}'")

  initialize: (minLogLevelStr, logPath) =>
    @_minLogLevel = @\_convertLogLevelStringToLevel(minLogLevelStr)
    assert.that(@_minLogLevel)
    file = io.open(logPath, "a")
    assert.that(file, "Could not open log file '#{logPath}'")
    file\setvbuf("line")
    @_fileStream = file

    vim.cmd [[augroup vimpFileLogStream]]
    vim.cmd [[au!]]
    vim.cmd [[au VimLeavePre * lua _vimp:_fileLogStream:dispose()]]
    vim.cmd [[augroup END]]

  dispose: =>
    @_fileStream\flush!

  log: (message, level) =>
    if @_minLogLevel >= level
      @_fileStream\write("#{log.levels.strings[level]}\t#{message}\n")

      -- Probably unnecessary every log
      -- @_fileStream\flush!
