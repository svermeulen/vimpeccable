
assert = require("vimp.util.assert")
log = require("vimp.util.log")

class CommandMapInfo
  new: (id, handler, name, options) =>
    @id = id
    @handler = handler
    @name = name
    @options = options

  remove_from_vim: =>
    vim.api.nvim_command("delcommand #{@name}")

  _get_n_args_from_handler: =>
    handler_info = debug.getinfo(@handler)

    if handler_info.isvararg
      return '*'

    if handler_info.nparams == 1
      return '1'

    if handler_info.nparams == 0
      return '0'

    return '*'

  _get_options_string: =>
    stringified_options = {}

    if @options.complete != nil
      assert.that(type(@options.complete) == 'string',
        "Expected type 'string' for option 'complete' but instead found '#{type(@options.complete)}'")
      table.insert stringified_options, "-complete=#{@options.complete}"

    return table.concat stringified_options, ' '

  _create_command_str: =>
    nargs = @\_get_n_args_from_handler!
    options_string = @\_get_options_string!

    if nargs == '0'
      return "command -nargs=0 #{options_string} #{@name} lua _vimp:_executeCommandMap(#{@id}, {})"

    if nargs == '1'
      return "command -nargs=1 #{options_string} #{@name} call luaeval(\"_vimp:_executeCommandMap(#{@id}, {_A})\", <q-args>)"

    return "command -nargs=* #{options_string} #{@name} call luaeval(\"_vimp:_executeCommandMap(#{@id}, _A)\", [<f-args>])"

  add_to_vim: =>
    command_str = @\_create_command_str!
    -- log.debug("Adding command: #{command_str}")
    vim.api.nvim_command(command_str)
