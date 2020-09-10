
assert = require("vimp.util.assert")
log = require("vimp.util.log")
tableUtil = require("vimp.util.table")
stringUtil = require("vimp.util.string")
util = require("vimp.util.util")
MapInfo = require("vimp.map_info")
CommandMapInfo = require("vimp.command_map_info")
createVimpErrorWrapper = require("vimp.error_wrapper")
UniqueTrie = require("vimp.unique_trie")
FileLogStream = require("vimp.util.file_log_stream")

ExtraOptions = { repeatable:true, override:true, buffer:true, chord:true }

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
  silent: 1
  logMessage: 2
  logMinimalUserStackTrace: 3
  logUserStackTrace: 4
  logFullStackTrace: 5
  rethrowMessage: 6
  none: 7

class Vimp
  new: =>
    @_mapsById = {}
    @_mapsInProgress = {}
    @_commandMapsById = {}
    @_uniqueMapIdCount = 1
    @_aliases = {}
    @_globalMapsByModeAndLhs = {}
    @_globalTrieByMode = {}
    @_globalTrieByModeRaw = {}
    @_bufferInfos = {}
    @_mapErrorHandlingStrategy = MapErrorStrategies.logMinimalUserStackTrace
    @_bufferBlockHandle = nil
    @_fileLogStream = nil

    for m in *AllModes
      @_globalMapsByModeAndLhs[m] = {}
      @_globalTrieByMode[m] = UniqueTrie()
      @_globalTrieByModeRaw[m] = UniqueTrie()

    @\_observeBufferUnload!

  _setPrintMinLogLevel: (minLogLevel) =>
    log.printLogStream.minLogLevel = log.convertLogLevelStringToLevel(minLogLevel)

  enableFileLogging: (minLogLevel, logFilePath) =>
    assert.that(@_fileLogStream == nil)
    @_fileLogStream = FileLogStream()
    @_fileLogStream\initialize(
      log.convertLogLevelStringToLevel(minLogLevel), logFilePath)
    table.insert(log.streams, @_fileLogStream)

  -- Use var args to work with commands
  showAllMaps: (mode) =>
    @\showMaps('', mode)

  _isCancellationMap: (map) =>
    return map.rhs == '<nop>' and stringUtil.endsWith(map.lhs, '<esc>')

  showMaps: (prefix, mode) =>
    mode = mode or 'n'
    assert.that(tableUtil.contains(AllModes, mode),
      "Invalid mode provided '#{mode}'")
    result = {}
    @_globalTrieByMode[mode]\visitSuffixes prefix, (suffix) ->
      mapping = @_globalMapsByModeAndLhs[mode][prefix .. suffix]
      assert.that(mapping)
      if not @\_isCancellationMap(mapping)
        table.insert(result, mapping)

    bufInfo = @_bufferInfos[vim.api.nvim_get_current_buf()]
    if bufInfo
      bufInfo.triesByMode[mode]\visitSuffixes prefix, (suffix) ->
        mapping = bufInfo.mapsByModeAndLhs[mode][prefix .. suffix]
        assert.that(mapping)
        if not @\_isCancellationMap(mapping)
          table.insert(result, mapping)

    output = "Maps for prefix '#{prefix}' (mode #{mode}):\n"
    if #result == 0
      output ..= "<None>"
    else
      table.sort(result, (left, right) -> left.lhs < right.lhs)
      for mapping in *result
        action = mapping\getRhsDisplayText!
        output ..= "#{mapping.lhs} -> #{action}\n"
    vim.api.nvim_out_write(output .. '\n')

  _getCurrentMapInfo: =>
    return @_mapsInProgress[#@_mapsInProgress]

  _getMapsInProgress: =>
    return @_mapsInProgress

  _getMapErrorHandlingStrategies: =>
    return MapErrorStrategies

  _getMapErrorHandlingStrategy: =>
    return @_mapErrorHandlingStrategy

  _setMapErrorHandlingStrategy: (strategy) =>
    assert.that(strategy >= 1 and strategy <= 7, "Invalid map error handling strategy '#{strategy}'")
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

    modeMaps, trie, trieRaw = @\_getModeMapsAndTrie(map)

    assert.that(modeMaps[map.lhs] != nil)
    modeMaps[map.lhs] = nil

    if not map.extraOptions.chord
      success = trie\tryRemove(map.lhs)
      assert.that(success)

      success = trieRaw\tryRemove(map.rawLhs)
      assert.that(success)

  _onBufferUnloaded: =>
    bufferHandle = tonumber(vim.fn.expand("<abuf>"))
    @\clearBufferMaps(bufferHandle)

  _generateNewMappingId: =>
    @_uniqueMapIdCount += 1
    return @_uniqueMapIdCount

  _validateArgs: (modes, options, extraOptions, lhsList, rhs) =>
    assert.that(#lhsList > 0)
    assert.that(#modes > 0, "Zero modes provided")

    assert.that(type(rhs) == 'function' or type(rhs) == 'string',
      "Expected type 'function' or 'string' for rhs argument but instead found '#{type(rhs)}'")

    for lhs in *lhsList
      assert.that(type(lhs) == 'string',
        "Expected type string for lhs argument but found '#{type(lhs)}'")

    for i = 1, #modes
      mode = modes\sub(i, i)
      assert.that(tableUtil.contains(AllModes, mode), "Invalid mode provided: '#{modes}'")

  -- 4 params = modes, options, lhs, rhs
  -- 3 params = (when string) modes, lhs, rhs
  -- 3 params = (when table) options, lhs, rhs
  -- 2 params = lhs, rhs
  _convertArgs: (arg1, arg2, arg3, arg4) =>
    local modes, optionsList, lhs, rhs

    if arg4 != nil
      modes = arg1
      optionsList = arg2
      lhs = arg3
      rhs = arg4
    else if arg3 != nil
      if type(arg1) == 'table'
        modes = 'n'
        optionsList = arg1
      else
        modes = arg1
        optionsList = {}
      lhs = arg2
      rhs = arg3
    else
      optionsList = {}
      modes = 'n'
      lhs = arg1
      rhs = arg2

    assert.that(type(optionsList) == 'table', "Expected to find an options table but instead found: #{optionsList}")

    if type(lhs) == 'string'
      lhs = {lhs}

    optionsMap = {x,true for x in *optionsList when not ExtraOptions[x]}
    extraOptionsMap = {x,true for x in *optionsList when ExtraOptions[x]}

    return modes, optionsMap, extraOptionsMap, lhs, rhs

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

    table.insert(@_mapsInProgress, map)
    -- Call user function and get the full stack trace if error occurs
    success, result = xpcall(map.rhs, debug.traceback)
    -- Remove the last element
    assert.that(#@_mapsInProgress > 0)
    table.remove(@_mapsInProgress)

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

  _addToTrieDryRun: (trie, map, mappingMap) =>
    assert.that(not map.extraOptions.chord)

    succeeded, existingPrefix, exactMatch = trie\tryAdd(map.lhs, true)

    if succeeded
      return true

    -- This should never happen because we check for duplicates before this
    assert.that(not exactMatch)

    conflictMapInfos = {}

    if #existingPrefix < #map.lhs
      -- In this case, the existingPrefix must match an actual map
      -- otherwise, the prefix would be a branch and therefore the
      -- add would have succeeded
      currentInfo = mappingMap[existingPrefix]
      assert.that(currentInfo)
      table.insert(conflictMapInfos, currentInfo)
    else
      assert.that(#existingPrefix == #map.lhs)

      trie\visitSuffixes map.lhs, (suffix) ->
        currentInfo = mappingMap[map.lhs .. suffix]
        assert.that(currentInfo)
        table.insert(conflictMapInfos, currentInfo)

    conflictOutput = stringUtil.join("\n", ["    #{x\toString!}" for x in *conflictMapInfos])
    error("Map conflict found when attempting to add map:\n    #{map\toString!}\nConflicts:\n#{conflictOutput}")

  _newBufInfo: =>
    bufInfo = {mapsByModeAndLhs: {}, triesByMode: {}, triesRawByMode: {}}

    for m in *AllModes
      bufInfo.mapsByModeAndLhs[m] = {}
      bufInfo.triesByMode[m] = UniqueTrie()
      bufInfo.triesRawByMode[m] = UniqueTrie()

    return bufInfo

  addChordCancellations: (mode, prefix) =>
    assert.that(tableUtil.contains(AllModes, mode),
      "Invalid mode provided to addChordCancellations '#{mode}'")
    local trieRaw
    if @_bufferBlockHandle != nil
      bufInfo = @_bufferInfos[vim.api.nvim_get_current_buf()]
      if bufInfo == nil
        return
      trieRaw = bufInfo.triesRawByMode[mode]
    else
      trieRaw = @_globalTrieByModeRaw[mode]
    prefixRaw = vim.api.nvim_replace_termcodes(prefix, true, false, true)
    escapeKey = '<esc>'
    escapeKeyRaw = vim.api.nvim_replace_termcodes(escapeKey, true, false, true)

    -- Note here that we have to use getAllBranches instead of visitBranches because
    -- otherwise we get into an infinite loop
    for suffix in *trieRaw\getAllBranches(prefixRaw)
      -- This check might not be necessary but better to be safe
      if not stringUtil.endsWith(suffix, escapeKey) and not stringUtil.endsWith(suffix, escapeKeyRaw)
        -- Suffix here is raw but that should be ok
        @\bind(mode, prefix .. suffix .. escapeKey, '<nop>')

  _getModeMapsAndTrie: (map) =>
    if map.bufferHandle != nil
      bufInfo = @_bufferInfos[map.bufferHandle]

      if bufInfo == nil
        bufInfo = @\_newBufInfo!
        @_bufferInfos[map.bufferHandle] = bufInfo

      return bufInfo.mapsByModeAndLhs[map.mode], bufInfo.triesByMode[map.mode], bufInfo.triesRawByMode[map.mode]

    return @_globalMapsByModeAndLhs[map.mode], @_globalTrieByMode[map.mode], @_globalTrieByModeRaw[map.mode]

  _addMapping: (map) =>
    modeMaps, trie, trieRaw = @\_getModeMapsAndTrie(map)

    existingMap = modeMaps[map.lhs]

    if existingMap
      assert.that(map.extraOptions.override,
        "Found duplicate mapping for keys '#{map.lhs}' in mode '#{map.mode}'.  Ignoring second attempt.  Current Mapping: #{existingMap\getRhsDisplayText!}, New Mapping: #{map\getRhsDisplayText!}")

      @\_removeMapping(existingMap)

    -- Do not add mappings that have the chord option to the trie
    -- This is important to avoid false positives for shadow detection
    -- For example:
    --   vimp.bind 'n', 'm', "d"
    --   vimp.bind 'n', 'mm', "D"
    -- This would normally be flagged as a duplicate even though
    -- it works fine in practice, because 'm' would always be followed
    -- by another key for the motion.  This can be avoided by changing to:
    --   vimp.bind 'n', {'chord'}, 'm', "d"
    --   vimp.bind 'n', 'mm', "D"
    shouldAddToTrie = not map.extraOptions.chord

    if shouldAddToTrie
      @\_addToTrieDryRun(trie, map, modeMaps)

    map\addToVim!
    -- Now that addToVim has succeeded, we can store the mapping
    -- We need to wait until after this point in case there's errors
    -- (eg. duplicate map)

    @_mapsById[map.id] = map
    modeMaps[map.lhs] = map

    if shouldAddToTrie
      succeeded, existingPrefix, exactMatch = trie\tryAdd(map.lhs)
      assert.that(succeeded)

      succeeded, existingPrefix, exactMatch = trieRaw\tryAdd(map.rawLhs)
      assert.that(succeeded)

  _getAliases: =>
    return @_aliases

  addAlias: (alias, replacement) =>
    assert.that(not @_aliases[alias], "Found multiple aliases with key '#{alias}'")
    @_aliases[alias] = replacement

  _applyAliases: (lhs) =>
    for k,v in pairs(@_aliases)
      lhs = stringUtil.replace(lhs, k, v)
    return lhs

  _createMapInfo: (mode, lhs, rhs, options, extraOptions) =>
    log.debug("Adding #{mode} mode map: #{lhs}")

    bufferHandle = @_bufferBlockHandle

    if extraOptions.buffer
      assert.that(bufferHandle == nil, "Do not specify <buffer> option when inside a call to vimp.addBufferMaps")
      bufferHandle = vim.api.nvim_get_current_buf()

    -- Do not use <unique> for buffer maps because it's very common to override global maps with buffer ones
    -- When extraOptions.override option is not provided, it will still make sure it doesn't collide with
    --  other buffer local ones
    if not extraOptions.override and bufferHandle == nil
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

    if type(rhs) == 'function'
      -- Neccessary to avoid printing out ':lua _vimp:_executeMap(146)' every time
      options.silent = true

    id = @\_generateNewMappingId!
    assert.that(@_mapsById[id] == nil)

    expandedLhs = @\_applyAliases(lhs)
    rawLhs = vim.api.nvim_replace_termcodes(expandedLhs, true, false, true)

    return MapInfo(
      id, mode, options, extraOptions, lhs, expandedLhs, rawLhs, rhs, bufferHandle)

  bind: (...) =>
    modes, options, extraOptions, lhsList, rhs = @\_convertArgs(...)
    -- Validate seperately because error_wrapper uses _convertArgs
    @\_validateArgs(modes, options, extraOptions, lhsList, rhs)
    assert.that(options.noremap == nil)
    options.noremap = true
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

  rbind: (...) =>
    modes, options, extraOptions, lhsList, rhs = @\_convertArgs(...)
    -- Validate seperately because error_wrapper uses _convertArgs
    @\_validateArgs(modes, options, extraOptions, lhsList, rhs)
    assert.that(options.noremap == nil)
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

  clearBufferMaps: (bufferHandle) =>
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

  unmapAll: =>
    log.debug("Unmapping all maps")

    count = 0
    for _, map in pairs(@_mapsById)
      @\_removeMapping(map)
      count += 1

    for mode in *AllModes
      assert.that(#tableUtil.getKeys(@_globalMapsByModeAndLhs[mode]) == 0)
      assert.that(@_globalTrieByMode[mode]\isEmpty!)
      assert.that(@_globalTrieByModeRaw[mode]\isEmpty!)

      for _, bufInfo in pairs(@_bufferInfos)
        assert.that(#tableUtil.getKeys(bufInfo.mapsByModeAndLhs[mode]) == 0)
        assert.that(bufInfo.triesByMode[mode]\isEmpty!)
        assert.that(bufInfo.triesRawByMode[mode]\isEmpty!)

    assert.that(#@_mapsById == 0)

    tableUtil.clear(@_bufferInfos)

    for _, map in pairs(@_commandMapsById)
      map\removeFromVim!

    tableUtil.clear(@_commandMapsById)
    tableUtil.clear(@_aliases)

    -- Don't bother resetting _uniqueMapIdCount to be extra safe
    log.debug("Successfully unmapped #{count} maps")

  -- Can either be called with a callback only (in which case it uses
  -- current buffer) or with a bufferhandle first then the callback
  addBufferMaps: (arg1, arg2) =>
    local bufferHandle, func
    if arg2 == nil
      bufferHandle = vim.api.nvim_get_current_buf()
      func = arg1
    else
      bufferHandle = arg1
      func = arg2
    assert.that(type(func) == 'function', "Unexpected parameter type given")
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
