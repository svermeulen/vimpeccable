
assert = require("vimp.util.assert")
log = require("vimp.util.log")

class FileLogStream
  new: =>
    @_file_stream = nil

  initialize: (min_log_level, log_path) =>
    log_path = vim.fn.expand(log_path)
    @_min_log_level = min_log_level
    assert.that(@_min_log_level)
    file = io.open(log_path, "a")
    assert.that(file, "Could not open log file '#{log_path}'")
    file\setvbuf("line")
    @_file_stream = file

    vim.api.nvim_command [[augroup vimpFileLogStream]]
    vim.api.nvim_command [[au!]]
    vim.api.nvim_command [[au VimLeavePre * lua _vimp._file_log_stream:dispose()]]
    vim.api.nvim_command [[augroup END]]

    @_file_stream\write("Log file initialized\n")
    @_file_stream\flush!

  dispose: =>
    @_file_stream\write("Closing log file!\n")
    @_file_stream\flush!
    @_file_stream\close!

  log: (message, level) =>
    if level >= @_min_log_level
      @_file_stream\write("#{log.levels.strings[level]}\t#{message}\n")
      -- Probably unnecessary every log
      -- @_file_stream\flush!
