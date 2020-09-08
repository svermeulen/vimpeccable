
assert = require("vimp.util.assert")
log = require("vimp.util.log")
tableUtil = require("vimp.util.table")
stringUtil = require("vimp.util.string")
util = require("vimp.util.util")
MapInfo = require("vimp.map_info")
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

  _addNonRecursiveMap: (mode, arg1, arg2, arg3) =>
    options, extraOptions, lhs, rhs = @\_convertArgs(arg1, arg2, arg3)
    assert.that(options.noremap == nil)
    options.noremap = true
    map = @\_createMapInfo(mode, lhs, rhs, options, extraOptions)
    @\_addMapping(map)

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
    map = @\_createMapInfo(mode, lhs, rhs, options, extraOptions)
    @\_addMapping(map)

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

export vimp, _vimp
_vimp = Vimp()
vimp = createVimpErrorWrapper!
return vimp
