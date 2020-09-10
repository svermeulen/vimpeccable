
assert = require("vimp.util.assert")
log = require("vimp.util.log")

class CommandMapInfo
  new: (id, handler, name) =>
    @id = id
    @handler = handler
    @name = name

  removeFromVim: =>
    vim.api.nvim_command("delcommand #{@name}")

  _getNArgsFromHandler: =>
    handlerInfo = debug.getinfo(@handler)

    if handlerInfo.isvararg
      return '*'

    if handlerInfo.nparams == 1
      return '1'

    if handlerInfo.nparams == 0
      return '0'

    return '*'

  _createCommandStr: =>
    nargs = @\_getNArgsFromHandler!

    if nargs == '0'
      return "command -nargs=0 #{@name} lua _vimp:_executeCommandMap(#{@id}, {})"

    if nargs == '1'
      return "command -nargs=1 #{@name} call luaeval(\"_vimp:_executeCommandMap(#{@id}, {_A})\", <q-args>)"

    return "command -nargs=* #{@name} call luaeval(\"_vimp:_executeCommandMap(#{@id}, _A)\", [<f-args>])"

  addToVim: =>
    commandStr = @\_createCommandStr!
    -- log.debug("Adding command: #{commandStr}")
    vim.api.nvim_command(commandStr)
