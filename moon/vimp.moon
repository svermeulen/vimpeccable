
assert = require("vimp.util.assert")
log = require("vimp.util.log")
try = require("vimp.util.try")
tableUtil = require("vimp.util.table")
util = require("vimp.util.util")
MapInfo = require("vimp.map_info")
createVimpErrorWrapper = require("vimp.error_wrapper")

ExtraOptions = { repeatable:true, force:true, buffer:true }

Modes =
  normal: 'n',
  visual: 'x',
  select: 's',
  operation: 'o',
  insert: 'i',
  change: 'c',
  terminal: 't',

AllModes = [v for _, v in pairs(Modes)]

MapErrorStrategies =
  logMessage: 1
  logUserStackTrace: 2
  logFullStackTrace: 3
  rethrowMessage: 4
  none: 5

class Vimp
  new: =>
    @_mapsById = {}
    @_uniqueMapIdCount = 1
    @_globalMapsByModeAndLhs = {x,{} for x in *AllModes}
    @_mapErrorHandlingStrategy = MapErrorStrategies.logUserStackTrace
    @\_initialize!

  _getMapErrorHandlingStrategies: =>
    return MapErrorStrategies

  _getMapErrorHandlingStrategy: =>
    return @_mapErrorHandlingStrategy

  _setMapErrorHandlingStrategy: (strategy) =>
    assert.that(strategy >= 1 and strategy <= 5, "Invalid map error handling strategy '#{strategy}'")
    @_mapErrorHandlingStrategy = strategy

  _initialize: =>
    @\_resetState!

    -- Note that we want to use BufUnload here and not BufDelete because BufDelete
    -- does not get triggered for unlisted buffers
    vim.cmd [[augroup vimpBufWatch]]
    vim.cmd [[au!]]
    vim.cmd [[au BufUnload * lua _vimp:_onBufferUnloaded()]]
    vim.cmd [[augroup END]]

  -- Note that this includes both buffer local maps and global maps
  _getTotalNumMaps: =>
    keys = tableUtil.getKeys(@_mapsById)
    return #keys

  _onBufferUnloaded: =>
    bufferHandle = tonumber(vim.fn.expand("<abuf>"))
    -- Store it first since we are removing from _mapsById at the same time
    bufferKeyMaps = [x for k, x in pairs(@_mapsById) when x.bufferHandle == bufferHandle]

    count = 0
    for map in *bufferKeyMaps
      map\removeFromVim!
      @_mapsById[map.id] = nil
      count += 1

    -- log.debug("Removed #{count} maps for #{bufferHandle}")

  _resetState: =>
    -- Don't bother resetting _uniqueMapIdCount to be extra safe
    tableUtil.clear(@_mapsById)

    for mode in *AllModes
      tableUtil.clear(@_globalMapsByModeAndLhs[mode])

  _generateNewMappingId: =>
    @_uniqueMapIdCount += 1
    return @_uniqueMapIdCount

  _convertArgs: (arg1, arg2, arg3) =>
    local optionsList, lhs, rhs

    if arg3 != nil
      optionsList = arg1
      lhs = arg2
      rhs = arg3
    else
      optionsList = {}
      lhs = arg1
      rhs = arg2

    assert.that(type(optionsList) == 'table')
    assert.that(type(lhs) == 'string')
    assert.that(type(rhs) == 'function' or type(rhs) == 'string')

    optionsMap = {x,true for x in *optionsList when not ExtraOptions[x]}
    extraOptionsMap = {x,true for x in *optionsList when ExtraOptions[x]}

    return optionsMap, extraOptionsMap, lhs, rhs

  _executeMap: (mapId) =>
    mapping = @_mapsById[mapId]

    assert.that(mapping != nil)

    if not mapping.options.expr
      if mapping.mode == 'x'
        util.normalBang('gv')
      elseif mapping.mode == 's'
        util.normalBang('gv<c-g>')

    assert.that(type(mapping.rhs) == 'function')

    -- Call user function and get the full stack trace if error occurs
    success, result = xpcall(mapping.rhs, debug.traceback)

    if not success
      -- Always rethrow on errors
      error("Error when executing map '#{mapping.lhs}': #{result}\n")

    if mapping.extraOptions.repeatable
      assert.that(not mapping.options.expr)
      vim.call('repeat#set', util.replaceSpecialChars(mapping.lhs))

    if mapping.options.expr
      -- This appears to be necessary even though I would expect
      -- vim to handle this for us
      return util.replaceSpecialChars(result)

    return nil

  _rhsToString: (rhs) =>
    if type(rhs) == 'string'
      return rhs

    assert.that(type(rhs) == 'function')
    return 'lua function'

  _addMapping: (mode, lhs, rhs, options, extraOptions) =>
    log.debug("Adding #{mode} mode map: #{lhs}")

    bufferHandle = nil

    if extraOptions.buffer
      bufferHandle = vim.api.nvim_get_current_buf()

    assert.that(options.unique == nil, "The <unique> option is already on by default, and is disabled with the <force> option")

    if not extraOptions.force
      options.unique = true

    if extraOptions.repeatable
      assert.that(not options.expr, "Using <expr> along with <repeatable> is currently not supported")
      assert.that(mode == 'n', "The <repeatable> flag is currently only supported when using 'n' mode")

      if type(rhs) == 'string'
        -- In this case we need to make it into a lua function so that our execute map function gets calls and we call repeat#set
        rhsStr = rhs
        rhsStrNoremap = options.noremap
        -- lua functions are always noremap
        options.noremap = true
        rhs = ->
          if rhsStrNoremap
            util.normalBang(rhsStr)
          else
            util.rnormal(rhsStr)

    id = @\_generateNewMappingId!
    mapInfo = MapInfo(id, mode, options, extraOptions, lhs, rhs, bufferHandle)
    assert.that(@_mapsById[id] == nil)

    currentInfo = @_globalMapsByModeAndLhs[mode][lhs]

    if currentInfo
      assert.that(extraOptions.force,
        "Found duplicate mapping for keys '#{lhs}' in mode '#{mode}'.  Ignoring second attempt.  Current Mapping: #{@\_rhsToString(currentInfo.rhs)}, New Mapping: #{@\_rhsToString(rhs)}")

      currentInfo\removeFromVim!
      @_mapsById[currentInfo.id] = nil
      @_globalMapsByModeAndLhs[mode][lhs] = nil

    mapInfo\addToVim!

    -- Do this after actually executing the mapping in case there's errors
    -- (eg. duplicate map)
    @_mapsById[id] = mapInfo
    @_globalMapsByModeAndLhs[mode][lhs] = mapInfo

  _addNonRecursiveMap: (mode, arg1, arg2, arg3) =>
    options, extraOptions, lhs, rhs = @\_convertArgs(arg1, arg2, arg3)
    assert.that(options.noremap == nil)
    options.noremap = true
    @\_addMapping(mode, lhs, rhs, options, extraOptions)

  tnoremap: (arg1, arg2, arg3) =>
    @\_addNonRecursiveMap('t', arg1, arg2, arg3)

  cnoremap: (arg1, arg2, arg3) =>
    @\_addNonRecursiveMap('c', arg1, arg2, arg3)

  snoremap: (arg1, arg2, arg3) =>
    @\_addNonRecursiveMap('s', arg1, arg2, arg3)

  onoremap: (arg1, arg2, arg3) =>
    @\_addNonRecursiveMap('o', arg1, arg2, arg3)

  vnoremap: (arg1, arg2, arg3) =>
    @\_addNonRecursiveMap('v', arg1, arg2, arg3)

  xnoremap: (arg1, arg2, arg3) =>
    @\_addNonRecursiveMap('x', arg1, arg2, arg3)

  inoremap: (arg1, arg2, arg3) =>
    @\_addNonRecursiveMap('i', arg1, arg2, arg3)

  nnoremap: (arg1, arg2, arg3) =>
    @\_addNonRecursiveMap('n', arg1, arg2, arg3)

  _addRecursiveMap: (mode, arg1, arg2, arg3) =>
    options, extraOptions, lhs, rhs = @\_convertArgs(arg1, arg2, arg3)
    assert.that(options.noremap == nil)
    @\_addMapping(mode, lhs, rhs, options, extraOptions)

  tmap: (arg1, arg2, arg3) =>
    @\_addRecursiveMap('t', arg1, arg2, arg3)

  cmap: (arg1, arg2, arg3) =>
    @\_addRecursiveMap('c', arg1, arg2, arg3)

  smap: (arg1, arg2, arg3) =>
    @\_addRecursiveMap('s', arg1, arg2, arg3)

  omap: (arg1, arg2, arg3) =>
    @\_addRecursiveMap('o', arg1, arg2, arg3)

  vmap: (arg1, arg2, arg3) =>
    @\_addRecursiveMap('v', arg1, arg2, arg3)

  xmap: (arg1, arg2, arg3) =>
    @\_addRecursiveMap('x', arg1, arg2, arg3)

  imap: (arg1, arg2, arg3) =>
    @\_addRecursiveMap('i', arg1, arg2, arg3)

  nmap: (arg1, arg2, arg3) =>
    @\_addRecursiveMap('n', arg1, arg2, arg3)

  unmapAll: =>
    log.debug("Unmapping all maps")

    count = 0
    for _, map in pairs(@_mapsById)
      map\removeFromVim!
      count += 1

    @\_resetState!
    log.debug("Successfully unmapped #{count} maps")

export vimp, _vimp
_vimp = Vimp()
vimp = createVimpErrorWrapper!
return vimp
