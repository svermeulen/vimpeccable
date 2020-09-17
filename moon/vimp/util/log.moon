
LogLevels =
  debug: 1
  info: 2
  warning: 3
  error: 4
  all: {1, 2, 3, 4}
  strings: {"debug", "info", "warning", "error"}

class PrintLogStream
  new: =>
    @min_log_level = LogLevels.warning

  log: (message, level) =>
    if level >= @min_log_level
      -- We could write to nvim_err_write instead here, but this causes exceptions to be triggered in some cases
      -- This can be especially bad for buffer local maps because it can make the file non-writable, since this
      -- occurs during the ft change event
      -- Better to just log the error to avoid bringing down the users entire config or to put vim in a bad state
      vim.api.nvim_out_write(
        "[vimp] #{LogLevels.strings[level]}: #{message}\n")

print_log_stream = PrintLogStream()

class log
  levels: LogLevels
  streams: {print_log_stream}
  print_log_stream: print_log_stream

  log: (message, level) ->
    if message == nil
      message = "nil"
    elseif type(message) != 'string'
      message = tostring(message)

    for stream in *log.streams
      stream\log(message, level)

  debug: (message) ->
    log.log(message, LogLevels.debug)

  info: (message) ->
    log.log(message, LogLevels.info)

  warning: (message) ->
    log.log(message, LogLevels.warning)

  error: (message) ->
    log.log(message, LogLevels.error)

  convert_log_level_string_to_level: (log_level_str) ->
    for i=1,#LogLevels.strings
      if log_level_str == LogLevels.strings[i]
        return i
    error("Invalid log level '#{log_level_str}'")

