
assert = require("vimp.util.assert")
log = require("vimp.util.log")
tableUtil = require("vimp.util.table")
stringUtil = require("vimp.util.string")
util = require("vimp.util.util")
MapInfo = require("vimp.map_info")
CommandMapInfo = require("vimp.command_map_info")
createVimpErrorWrapper = require("vimp.error_wrapper")
UniqueTrie = require("vimp.unique_trie")

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
    @_commandMapsById = {}
    @_uniqueMapIdCount = 1
    @_globalMapsByModeAndLhs = {}
    @_globalTrieByMode = {}
    @_bufferInfos = {}
    @_mapErrorHandlingStrategy = MapErrorStrategies.logUserStackTrace
    @_bufferBlockHandle = nil

    for m in *AllModes
      @_globalMapsByModeAndLhs[m] = {}
      @_globalTrieByMode[m] = UniqueTrie()

    @\_observeBufferUnload!

  _getMapErrorHandlingStrategies: =>
    return MapErrorStrategies

  _getMapErrorHandlingStrategy: =>
    return @_mapErrorHandlingStrategy

  _setMapErrorHandlingStrategy: (strategy) =>
    assert.that(strategy >= 1 and strategy <= 5, "Invalid map error handling strategy '#{strategy}'")
    @_mapErrorHandlingStrategy = strategy

  _observeBufferUnload: =>
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

  _removeMapping: (map) =>
    -- Remove from vim first in case it fails
    map\removeFromVim!
    @_mapsById[map.id] = nil

    modeMaps, trie = @\_getModeMapsAndTrie(map)

    assert.that(modeMaps[map.lhs] != nil)
    modeMaps[map.lhs] = nil

    success = trie\tryRemove(map.lhs)
    assert.that(success)

  _onBufferUnloaded: =>
    bufferHandle = tonumber(vim.fn.expand("<abuf>"))

    -- Store it first since we are removing from _mapsById at the same time
    bufferMaps = [x for k, x in pairs(@_mapsById) when x.bufferHandle == bufferHandle]

    if #bufferMaps == 0
      assert.that(@_bufferInfos[bufferHandle] == nil)
      return

    bufInfo = @_bufferInfos[bufferHandle]
    assert.that(bufInfo)

    count = 0
    for map in *bufferMaps
      @\_removeMapping(map)
      count += 1

    @_bufferInfos[bufferHandle] = nil

    -- log.debug("Removed #{count} maps for #{bufferHandle}")

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

    lhsList = {}
    if type(lhs) == 'table'
      for entry in *lhs
        assert.that(type(entry) == 'string')
        table.insert(lhsList, entry)
    else
      assert.that(type(lhs) == 'string')
      table.insert(lhsList, lhs)

    assert.that(type(rhs) == 'function' or type(rhs) == 'string')

    optionsMap = {x,true for x in *optionsList when not ExtraOptions[x]}
    extraOptionsMap = {x,true for x in *optionsList when ExtraOptions[x]}

    return optionsMap, extraOptionsMap, lhsList, rhs

  _executeCommandMap: (mapId, userArgs) =>
    map = @_commandMapsById[mapId]

    assert.that(map != nil)

    action = ->
      map.handler(unpack(userArgs))

    -- Call user function and get the full stack trace if error occurs
    success, result = xpcall(action, debug.traceback)

    if not success
      -- Always rethrow on errors
      error("Error when executing command '#{map.name}': #{result}\n")

  _executeMap: (mapId) =>
    map = @_mapsById[mapId]

    assert.that(map != nil)

    if not map.options.expr
      if map.mode == 'x'
        util.normalBang('gv')
      elseif map.mode == 's'
        util.normalBang('gv<c-g>')

    assert.that(type(map.rhs) == 'function')

    -- Call user function and get the full stack trace if error occurs
    success, result = xpcall(map.rhs, debug.traceback)

    if not success
      -- Always rethrow on errors
      error("Error when executing map '#{map.lhs}': #{result}\n")

    if map.extraOptions.repeatable
      assert.that(not map.options.expr)
      vim.call('repeat#set', util.replaceSpecialChars(map.lhs))

    if map.options.expr
      -- This appears to be necessary even though I would expect
      -- vim to handle this for us
      return util.replaceSpecialChars(result)

    return nil

  _addToTrieDryRun: (trie, mapInfo, mappingMap) =>
    succeeded, existingPrefix, exactMatch = trie\tryAdd(mapInfo.lhs, true)

    if succeeded
      return true

    -- This should never happen because we check for duplicates before this
    assert.that(not exactMatch)

    conflictMapInfos = {}

    if #existingPrefix < #mapInfo.lhs
      -- In this case, the existingPrefix must match an actual map
      -- otherwise, the prefix would be a branch and therefore the
      -- add would have succeeded
      currentInfo = mappingMap[existingPrefix]
      assert.that(currentInfo)
      table.insert(conflictMapInfos, currentInfo)
    else
      assert.that(#existingPrefix == #mapInfo.lhs)

      trie\visitSuffixes mapInfo.lhs, (suffix) ->
        currentInfo = mappingMap[mapInfo.lhs .. suffix]
        assert.that(currentInfo)
        table.insert(conflictMapInfos, currentInfo)

    conflictOutput = stringUtil.join("\n", ["    #{x\toString!}" for x in *conflictMapInfos])
    error("Map conflict found when attempting to add map:\n    #{mapInfo\toString!}\nConflicts:\n#{conflictOutput}")

  _newBufInfo: =>
    bufInfo = {mapsByModeAndLhs: {}, triesByMode: {}}

    for m in *AllModes
      bufInfo.mapsByModeAndLhs[m] = {}
      bufInfo.triesByMode[m] = UniqueTrie()

    return bufInfo

  _getModeMapsAndTrie: (map) =>
    if map.bufferHandle != nil
      bufInfo = @_bufferInfos[map.bufferHandle]

      if bufInfo == nil
        bufInfo = @\_newBufInfo!
        @_bufferInfos[map.bufferHandle] = bufInfo

      return bufInfo.mapsByModeAndLhs[map.mode], bufInfo.triesByMode[map.mode]

    return @_globalMapsByModeAndLhs[map.mode], @_globalTrieByMode[map.mode]

  _addMapping: (map) =>
    modeMaps, trie = @\_getModeMapsAndTrie(map)

    existingMap = modeMaps[map.lhs]

    if existingMap
      assert.that(map.extraOptions.force,
        "Found duplicate mapping for keys '#{map.lhs}' in mode '#{map.mode}'.  Ignoring second attempt.  Current Mapping: #{existingMap\getRhsDisplayText!}, New Mapping: #{map\getRhsDisplayText!}")

      @\_removeMapping(existingMap)

    @\_addToTrieDryRun(trie, map, modeMaps)

    map\addToVim!
    -- Now that addToVim has succeeded, we can store the mapping
    -- We need to wait until after this point in case there's errors
    -- (eg. duplicate map)

    @_mapsById[map.id] = map
    modeMaps[map.lhs] = map

    succeeded, existingPrefix, exactMatch = trie\tryAdd(map.lhs)
    assert.that(succeeded)

  _createMapInfo: (mode, lhs, rhs, options, extraOptions) =>
    log.debug("Adding #{mode} mode map: #{lhs}")

    bufferHandle = @_bufferBlockHandle

    if extraOptions.buffer
      assert.that(bufferHandle == nil, "Do not specify <buffer> option when inside a call to vimp.addBufferMaps")
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
    assert.that(@_mapsById[id] == nil)

    return MapInfo(
      id, mode, options, extraOptions, lhs, rhs, bufferHandle)

  bind: (modes, ...) =>
    options, extraOptions, lhsList, rhs = @\_convertArgs(...)
    assert.that(options.noremap == nil)
    options.noremap = true
    assert.that(#lhsList > 0)
    assert.that(#modes > 0)
    for lhs in *lhsList
      for i = 1, #modes
        mode = modes\sub(i, i)
        map = @\_createMapInfo(
          mode, lhs, rhs, tableUtil.shallowCopy(options), tableUtil.shallowCopy(extraOptions))
        @\_addMapping(map)

  tnoremap: (...) =>
    @\bind('t', ...)

  cnoremap: (...) =>
    @\bind('c', ...)

  snoremap: (...) =>
    @\bind('s', ...)

  onoremap: (...) =>
    @\bind('o', ...)

  vnoremap: (...) =>
    @\bind('v', ...)

  xnoremap: (...) =>
    @\bind('x', ...)

  inoremap: (...) =>
    @\bind('i', ...)

  nnoremap: (...) =>
    @\bind('n', ...)

  rbind: (modes, ...) =>
    options, extraOptions, lhsList, rhs = @\_convertArgs(...)
    assert.that(options.noremap == nil)
    assert.that(#lhsList > 0)
    assert.that(#modes > 0)
    for lhs in *lhsList
      for i = 1, #modes
        mode = modes\sub(i, i)
        map = @\_createMapInfo(
          mode, lhs, rhs, tableUtil.shallowCopy(options), tableUtil.shallowCopy(extraOptions))
        @\_addMapping(map)

  tmap: (...) =>
    @\rbind('t', ...)

  cmap: (...) =>
    @\rbind('c', ...)

  smap: (...) =>
    @\rbind('s', ...)

  omap: (...) =>
    @\rbind('o', ...)

  vmap: (...) =>
    @\rbind('v', ...)

  xmap: (...) =>
    @\rbind('x', ...)

  imap: (...) =>
    @\rbind('i', ...)

  nmap: (...) =>
    @\rbind('n', ...)

  unmapAll: =>
    log.debug("Unmapping all maps")

    count = 0
    for _, map in pairs(@_mapsById)
      @\_removeMapping(map)
      count += 1

    for mode in *AllModes
      assert.that(#tableUtil.getKeys(@_globalMapsByModeAndLhs[mode]) == 0)
      assert.that(@_globalTrieByMode[mode]\isEmpty!)

      for _, bufInfo in pairs(@_bufferInfos)
        assert.that(#tableUtil.getKeys(bufInfo.mapsByModeAndLhs[mode]) == 0)
        assert.that(bufInfo.triesByMode[mode]\isEmpty!)

    assert.that(#@_mapsById == 0)

    tableUtil.clear(@_bufferInfos)

    for _, map in pairs(@_commandMapsById)
      map\removeFromVim!

    tableUtil.clear(@_commandMapsById)

    -- Don't bother resetting _uniqueMapIdCount to be extra safe
    log.debug("Successfully unmapped #{count} maps")

  addBufferMaps: (bufferHandle, func) =>
    assert.that(bufferHandle != nil)
    assert.that(@_bufferBlockHandle == nil, "Already in a call to vimp.addBufferMaps!  Must exit this first before attempting another.")
    @_bufferBlockHandle = bufferHandle
    ok, retVal = pcall(func)
    assert.isEqual(@_bufferBlockHandle, bufferHandle)
    @_bufferBlockHandle = nil

    if not ok
      error(retVal, 2)

  mapCommand: (name, handler) =>
    assert.that(@_bufferBlockHandle == nil, "Buffer local commands are not currently supported")

    id = @\_generateNewMappingId!
    map = CommandMapInfo(id, handler, name)
    assert.that(@_commandMapsById[map.id] == nil)
    map\addToVim!
    @_commandMapsById[map.id] = map

export vimp, _vimp
_vimp = Vimp()
vimp = createVimpErrorWrapper!
return vimp
