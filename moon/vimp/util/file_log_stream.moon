
assert = require("vimp.util.assert")
log = require("vimp.util.log")

class FileLogStream
  new: =>
    @_fileStream = nil

  initialize: (minLogLevel, logPath) =>
    logPath = vim.fn.expand(logPath)
    @_minLogLevel = minLogLevel
    assert.that(@_minLogLevel)
    file = io.open(logPath, "a")
    assert.that(file, "Could not open log file '#{logPath}'")
    file\setvbuf("line")
    @_fileStream = file

    vim.api.nvim_command [[augroup vimpFileLogStream]]
    vim.api.nvim_command [[au!]]
    vim.api.nvim_command [[au VimLeavePre * lua _vimp._fileLogStream:dispose()]]
    vim.api.nvim_command [[augroup END]]

    @_fileStream\write("Log file initialized\n")
    @_fileStream\flush!

  dispose: =>
    @_fileStream\write("Closing log file!\n")
    @_fileStream\flush!
    @_fileStream\close!

  log: (message, level) =>
    if level >= @_minLogLevel
      @_fileStream\write("#{log.levels.strings[level]}\t#{message}\n")
      -- Probably unnecessary every log
      -- @_fileStream\flush!
