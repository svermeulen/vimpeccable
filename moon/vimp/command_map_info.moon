
assert = require("vimp.util.assert")
log = require("vimp.util.log")

class CommandMapInfo
  new: (id, handler, name) =>
    @id = id
    @handler = handler
    @name = name

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

  _create_command_str: =>
    nargs = @\_get_n_args_from_handler!

    if nargs == '0'
      return "command -nargs=0 #{@name} lua _vimp:_executeCommandMap(#{@id}, {})"

    if nargs == '1'
      return "command -nargs=1 #{@name} call luaeval(\"_vimp:_executeCommandMap(#{@id}, {_A})\", <q-args>)"

    return "command -nargs=* #{@name} call luaeval(\"_vimp:_executeCommandMap(#{@id}, _A)\", [<f-args>])"

  add_to_vim: =>
    command_str = @\_create_command_str!
    -- log.debug("Adding command: #{command_str}")
    vim.api.nvim_command(command_str)
