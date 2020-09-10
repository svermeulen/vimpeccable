local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local tableUtil = require("vimp.util.table")
local stringUtil = require("vimp.util.string")
local util = require("vimp.util.util")
local MapInfo = require("vimp.map_info")
local CommandMapInfo = require("vimp.command_map_info")
local createVimpErrorWrapper = require("vimp.error_wrapper")
local UniqueTrie = require("vimp.unique_trie")
local FileLogStream = require("vimp.util.file_log_stream")
local ExtraOptions = {
  repeatable = true,
  override = true,
  buffer = true,
  chord = true
}
local Modes = {
  normal = 'n',
  visual = 'x',
  select = 's',
  operation = 'o',
  insert = 'i',
  change = 'c',
  terminal = 't'
}
local AllModes
do
  local _accum_0 = { }
  local _len_0 = 1
  for _, v in pairs(Modes) do
    _accum_0[_len_0] = v
    _len_0 = _len_0 + 1
  end
  AllModes = _accum_0
end
local MapErrorStrategies = {
  silent = 1,
  logMessage = 2,
  logMinimalUserStackTrace = 3,
  logUserStackTrace = 4,
  logFullStackTrace = 5,
  rethrowMessage = 6,
  none = 7
}
local Vimp
do
  local _class_0
  local _base_0 = {
    _setPrintMinLogLevel = function(self, minLogLevel)
      log.printLogStream.minLogLevel = log.convertLogLevelStringToLevel(minLogLevel)
    end,
    enableFileLogging = function(self, minLogLevel, logFilePath)
      assert.that(self._fileLogStream == nil)
      self._fileLogStream = FileLogStream()
      self._fileLogStream:initialize(log.convertLogLevelStringToLevel(minLogLevel), logFilePath)
      return table.insert(log.streams, self._fileLogStream)
    end,
    showAllMaps = function(self, mode)
      return self:showMaps('', mode)
    end,
    _isCancellationMap = function(self, map)
      return map.rhs == '<nop>' and stringUtil.endsWith(map.lhs, '<esc>')
    end,
    showMaps = function(self, prefix, mode)
      mode = mode or 'n'
      assert.that(tableUtil.contains(AllModes, mode), "Invalid mode provided '" .. tostring(mode) .. "'")
      local result = { }
      self._globalTrieByMode[mode]:visitSuffixes(prefix, function(suffix)
        local mapping = self._globalMapsByModeAndLhs[mode][prefix .. suffix]
        assert.that(mapping)
        if not self:_isCancellationMap(mapping) then
          return table.insert(result, mapping)
        end
      end)
      local bufInfo = self._bufferInfos[vim.api.nvim_get_current_buf()]
      if bufInfo then
        bufInfo.triesByMode[mode]:visitSuffixes(prefix, function(suffix)
          local mapping = bufInfo.mapsByModeAndLhs[mode][prefix .. suffix]
          assert.that(mapping)
          if not self:_isCancellationMap(mapping) then
            return table.insert(result, mapping)
          end
        end)
      end
      local output = "Maps for prefix '" .. tostring(prefix) .. "' (mode " .. tostring(mode) .. "):\n"
      if #result == 0 then
        output = output .. "<None>"
      else
        table.sort(result, function(left, right)
          return left.lhs < right.lhs
        end)
        for _index_0 = 1, #result do
          local mapping = result[_index_0]
          local action = mapping:getRhsDisplayText()
          output = output .. tostring(mapping.lhs) .. " -> " .. tostring(action) .. "\n"
        end
      end
      return vim.api.nvim_out_write(output .. '\n')
    end,
    _getCurrentMapInfo = function(self)
      return self._mapsInProgress[#self._mapsInProgress]
    end,
    _getMapsInProgress = function(self)
      return self._mapsInProgress
    end,
    _getMapErrorHandlingStrategies = function(self)
      return MapErrorStrategies
    end,
    _getMapErrorHandlingStrategy = function(self)
      return self._mapErrorHandlingStrategy
    end,
    _setMapErrorHandlingStrategy = function(self, strategy)
      assert.that(strategy >= 1 and strategy <= 7, "Invalid map error handling strategy '" .. tostring(strategy) .. "'")
      self._mapErrorHandlingStrategy = strategy
    end,
    _observeBufferUnload = function(self)
      vim.api.nvim_command([[augroup vimpBufWatch]])
      vim.api.nvim_command([[au!]])
      vim.api.nvim_command([[au BufUnload * lua _vimp:_onBufferUnloaded()]])
      return vim.api.nvim_command([[augroup END]])
    end,
    _getTotalNumMaps = function(self)
      local keys = tableUtil.getKeys(self._mapsById)
      return #keys
    end,
    _removeMapping = function(self, map)
      map:removeFromVim()
      self._mapsById[map.id] = nil
      local modeMaps, trie, trieRaw = self:_getModeMapsAndTrie(map)
      assert.that(modeMaps[map.lhs] ~= nil)
      modeMaps[map.lhs] = nil
      if not map.extraOptions.chord then
        local success = trie:tryRemove(map.lhs)
        assert.that(success)
        success = trieRaw:tryRemove(map.rawLhs)
        return assert.that(success)
      end
    end,
    _onBufferUnloaded = function(self)
      local bufferHandle = tonumber(vim.api.nvim_call_function("expand", {
        "<abuf>"
      }))
      return self:clearBufferMaps(bufferHandle)
    end,
    _generateNewMappingId = function(self)
      self._uniqueMapIdCount = self._uniqueMapIdCount + 1
      return self._uniqueMapIdCount
    end,
    _validateArgs = function(self, modes, options, extraOptions, lhsList, rhs)
      assert.that(#lhsList > 0)
      assert.that(#modes > 0, "Zero modes provided")
      assert.that(type(rhs) == 'function' or type(rhs) == 'string', "Expected type 'function' or 'string' for rhs argument but instead found '" .. tostring(type(rhs)) .. "'")
      for _index_0 = 1, #lhsList do
        local lhs = lhsList[_index_0]
        assert.that(type(lhs) == 'string', "Expected type string for lhs argument but found '" .. tostring(type(lhs)) .. "'")
      end
      for i = 1, #modes do
        local mode = modes:sub(i, i)
        assert.that(tableUtil.contains(AllModes, mode), "Invalid mode provided: '" .. tostring(modes) .. "'")
      end
    end,
    _convertArgs = function(self, arg1, arg2, arg3, arg4)
      local modes, optionsList, lhs, rhs
      if arg4 ~= nil then
        modes = arg1
        optionsList = arg2
        lhs = arg3
        rhs = arg4
      else
        if arg3 ~= nil then
          if type(arg1) == 'table' then
            modes = 'n'
            optionsList = arg1
          else
            modes = arg1
            optionsList = { }
          end
          lhs = arg2
          rhs = arg3
        else
          optionsList = { }
          modes = 'n'
          lhs = arg1
          rhs = arg2
        end
      end
      assert.that(type(optionsList) == 'table', "Expected to find an options table but instead found: " .. tostring(optionsList))
      if type(lhs) == 'string' then
        lhs = {
          lhs
        }
      end
      local optionsMap
      do
        local _tbl_0 = { }
        for _index_0 = 1, #optionsList do
          local x = optionsList[_index_0]
          if not ExtraOptions[x] then
            _tbl_0[x] = true
          end
        end
        optionsMap = _tbl_0
      end
      local extraOptionsMap
      do
        local _tbl_0 = { }
        for _index_0 = 1, #optionsList do
          local x = optionsList[_index_0]
          if ExtraOptions[x] then
            _tbl_0[x] = true
          end
        end
        extraOptionsMap = _tbl_0
      end
      return modes, optionsMap, extraOptionsMap, lhs, rhs
    end,
    _executeCommandMap = function(self, mapId, userArgs)
      local map = self._commandMapsById[mapId]
      assert.that(map ~= nil)
      local action
      action = function()
        return map.handler(unpack(userArgs))
      end
      local success, result = xpcall(action, debug.traceback)
      if not success then
        return error("Error when executing command '" .. tostring(map.name) .. "': " .. tostring(result) .. "\n")
      end
    end,
    _executeMap = function(self, mapId)
      local map = self._mapsById[mapId]
      assert.that(map ~= nil)
      if not map.options.expr then
        if map.mode == 'x' then
          util.normalBang('gv')
        elseif map.mode == 's' then
          util.normalBang('gv<c-g>')
        end
      end
      assert.that(type(map.rhs) == 'function')
      table.insert(self._mapsInProgress, map)
      local success, result = xpcall(map.rhs, debug.traceback)
      assert.that(#self._mapsInProgress > 0)
      table.remove(self._mapsInProgress)
      if not success then
        error("Error when executing map '" .. tostring(map.lhs) .. "': " .. tostring(result) .. "\n")
      end
      if map.extraOptions.repeatable then
        assert.that(not map.options.expr)
        vim.api.nvim_call_function('repeat#set', {
          util.replaceSpecialChars(map.lhs)
        })
      end
      if map.options.expr then
        return util.replaceSpecialChars(result)
      end
      return nil
    end,
    _addToTrieDryRun = function(self, trie, map, mappingMap)
      assert.that(not map.extraOptions.chord)
      local succeeded, existingPrefix, exactMatch = trie:tryAdd(map.lhs, true)
      if succeeded then
        return true
      end
      assert.that(not exactMatch)
      local conflictMapInfos = { }
      if #existingPrefix < #map.lhs then
        local currentInfo = mappingMap[existingPrefix]
        assert.that(currentInfo)
        table.insert(conflictMapInfos, currentInfo)
      else
        assert.that(#existingPrefix == #map.lhs)
        trie:visitSuffixes(map.lhs, function(suffix)
          local currentInfo = mappingMap[map.lhs .. suffix]
          assert.that(currentInfo)
          return table.insert(conflictMapInfos, currentInfo)
        end)
      end
      local conflictOutput = stringUtil.join("\n", (function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #conflictMapInfos do
          local x = conflictMapInfos[_index_0]
          _accum_0[_len_0] = "    " .. tostring(x:toString())
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
      return error("Map conflict found when attempting to add map:\n    " .. tostring(map:toString()) .. "\nConflicts:\n" .. tostring(conflictOutput))
    end,
    _newBufInfo = function(self)
      local bufInfo = {
        mapsByModeAndLhs = { },
        triesByMode = { },
        triesRawByMode = { }
      }
      for _index_0 = 1, #AllModes do
        local m = AllModes[_index_0]
        bufInfo.mapsByModeAndLhs[m] = { }
        bufInfo.triesByMode[m] = UniqueTrie()
        bufInfo.triesRawByMode[m] = UniqueTrie()
      end
      return bufInfo
    end,
    addChordCancellations = function(self, mode, prefix)
      assert.that(tableUtil.contains(AllModes, mode), "Invalid mode provided to addChordCancellations '" .. tostring(mode) .. "'")
      local trieRaw
      if self._bufferBlockHandle ~= nil then
        local bufInfo = self._bufferInfos[vim.api.nvim_get_current_buf()]
        if bufInfo == nil then
          return 
        end
        trieRaw = bufInfo.triesRawByMode[mode]
      else
        trieRaw = self._globalTrieByModeRaw[mode]
      end
      local prefixRaw = vim.api.nvim_replace_termcodes(prefix, true, false, true)
      local escapeKey = '<esc>'
      local escapeKeyRaw = vim.api.nvim_replace_termcodes(escapeKey, true, false, true)
      local _list_0 = trieRaw:getAllBranches(prefixRaw)
      for _index_0 = 1, #_list_0 do
        local suffix = _list_0[_index_0]
        if not stringUtil.endsWith(suffix, escapeKey) and not stringUtil.endsWith(suffix, escapeKeyRaw) then
          self:bind(mode, prefix .. suffix .. escapeKey, '<nop>')
        end
      end
    end,
    _getModeMapsAndTrie = function(self, map)
      if map.bufferHandle ~= nil then
        local bufInfo = self._bufferInfos[map.bufferHandle]
        if bufInfo == nil then
          bufInfo = self:_newBufInfo()
          self._bufferInfos[map.bufferHandle] = bufInfo
        end
        return bufInfo.mapsByModeAndLhs[map.mode], bufInfo.triesByMode[map.mode], bufInfo.triesRawByMode[map.mode]
      end
      return self._globalMapsByModeAndLhs[map.mode], self._globalTrieByMode[map.mode], self._globalTrieByModeRaw[map.mode]
    end,
    _addMapping = function(self, map)
      local modeMaps, trie, trieRaw = self:_getModeMapsAndTrie(map)
      local existingMap = modeMaps[map.lhs]
      if existingMap then
        assert.that(map.extraOptions.override, "Found duplicate mapping for keys '" .. tostring(map.lhs) .. "' in mode '" .. tostring(map.mode) .. "'.  Ignoring second attempt.  Current Mapping: " .. tostring(existingMap:getRhsDisplayText()) .. ", New Mapping: " .. tostring(map:getRhsDisplayText()))
        self:_removeMapping(existingMap)
      end
      local shouldAddToTrie = not map.extraOptions.chord
      if shouldAddToTrie then
        self:_addToTrieDryRun(trie, map, modeMaps)
      end
      map:addToVim()
      self._mapsById[map.id] = map
      modeMaps[map.lhs] = map
      if shouldAddToTrie then
        local succeeded, existingPrefix, exactMatch = trie:tryAdd(map.lhs)
        assert.that(succeeded)
        succeeded, existingPrefix, exactMatch = trieRaw:tryAdd(map.rawLhs)
        return assert.that(succeeded)
      end
    end,
    _getAliases = function(self)
      return self._aliases
    end,
    addAlias = function(self, alias, replacement)
      assert.that(not self._aliases[alias], "Found multiple aliases with key '" .. tostring(alias) .. "'")
      self._aliases[alias] = replacement
    end,
    _applyAliases = function(self, lhs)
      for k, v in pairs(self._aliases) do
        lhs = stringUtil.replace(lhs, k, v)
      end
      return lhs
    end,
    _createMapInfo = function(self, mode, lhs, rhs, options, extraOptions)
      log.debug("Adding " .. tostring(mode) .. " mode map: " .. tostring(lhs))
      local bufferHandle = self._bufferBlockHandle
      if extraOptions.buffer then
        assert.that(bufferHandle == nil, "Do not specify <buffer> option when inside a call to vimp.addBufferMaps")
        bufferHandle = vim.api.nvim_get_current_buf()
      end
      if not extraOptions.override and bufferHandle == nil then
        options.unique = true
      end
      if extraOptions.repeatable then
        assert.that(not options.expr, "Using <expr> along with <repeatable> is currently not supported")
        assert.that(mode == 'n', "The <repeatable> flag is currently only supported when using 'n' mode")
        if type(rhs) == 'string' then
          local rhsStr = rhs
          local rhsStrNoremap = options.noremap
          options.noremap = true
          rhs = function()
            if rhsStrNoremap then
              return util.normalBang(rhsStr)
            else
              return util.rnormal(rhsStr)
            end
          end
        end
      end
      if type(rhs) == 'function' then
        options.silent = true
      end
      local id = self:_generateNewMappingId()
      assert.that(self._mapsById[id] == nil)
      local expandedLhs = self:_applyAliases(lhs)
      local rawLhs = vim.api.nvim_replace_termcodes(expandedLhs, true, false, true)
      return MapInfo(id, mode, options, extraOptions, lhs, expandedLhs, rawLhs, rhs, bufferHandle)
    end,
    bind = function(self, ...)
      local modes, options, extraOptions, lhsList, rhs = self:_convertArgs(...)
      self:_validateArgs(modes, options, extraOptions, lhsList, rhs)
      assert.that(options.noremap == nil)
      options.noremap = true
      for _index_0 = 1, #lhsList do
        local lhs = lhsList[_index_0]
        for i = 1, #modes do
          local mode = modes:sub(i, i)
          local map = self:_createMapInfo(mode, lhs, rhs, tableUtil.shallowCopy(options), tableUtil.shallowCopy(extraOptions))
          self:_addMapping(map)
        end
      end
    end,
    tnoremap = function(self, ...)
      return self:bind('t', ...)
    end,
    cnoremap = function(self, ...)
      return self:bind('c', ...)
    end,
    snoremap = function(self, ...)
      return self:bind('s', ...)
    end,
    onoremap = function(self, ...)
      return self:bind('o', ...)
    end,
    vnoremap = function(self, ...)
      return self:bind('v', ...)
    end,
    xnoremap = function(self, ...)
      return self:bind('x', ...)
    end,
    inoremap = function(self, ...)
      return self:bind('i', ...)
    end,
    nnoremap = function(self, ...)
      return self:bind('n', ...)
    end,
    rbind = function(self, ...)
      local modes, options, extraOptions, lhsList, rhs = self:_convertArgs(...)
      self:_validateArgs(modes, options, extraOptions, lhsList, rhs)
      assert.that(options.noremap == nil)
      for _index_0 = 1, #lhsList do
        local lhs = lhsList[_index_0]
        for i = 1, #modes do
          local mode = modes:sub(i, i)
          local map = self:_createMapInfo(mode, lhs, rhs, tableUtil.shallowCopy(options), tableUtil.shallowCopy(extraOptions))
          self:_addMapping(map)
        end
      end
    end,
    tmap = function(self, ...)
      return self:rbind('t', ...)
    end,
    cmap = function(self, ...)
      return self:rbind('c', ...)
    end,
    smap = function(self, ...)
      return self:rbind('s', ...)
    end,
    omap = function(self, ...)
      return self:rbind('o', ...)
    end,
    vmap = function(self, ...)
      return self:rbind('v', ...)
    end,
    xmap = function(self, ...)
      return self:rbind('x', ...)
    end,
    imap = function(self, ...)
      return self:rbind('i', ...)
    end,
    nmap = function(self, ...)
      return self:rbind('n', ...)
    end,
    clearBufferMaps = function(self, bufferHandle)
      local bufferMaps
      do
        local _accum_0 = { }
        local _len_0 = 1
        for k, x in pairs(self._mapsById) do
          if x.bufferHandle == bufferHandle then
            _accum_0[_len_0] = x
            _len_0 = _len_0 + 1
          end
        end
        bufferMaps = _accum_0
      end
      if #bufferMaps == 0 then
        assert.that(self._bufferInfos[bufferHandle] == nil)
        return 
      end
      local bufInfo = self._bufferInfos[bufferHandle]
      assert.that(bufInfo)
      local count = 0
      for _index_0 = 1, #bufferMaps do
        local map = bufferMaps[_index_0]
        self:_removeMapping(map)
        count = count + 1
      end
      self._bufferInfos[bufferHandle] = nil
    end,
    unmapAll = function(self)
      log.debug("Unmapping all maps")
      local count = 0
      for _, map in pairs(self._mapsById) do
        self:_removeMapping(map)
        count = count + 1
      end
      for _index_0 = 1, #AllModes do
        local mode = AllModes[_index_0]
        assert.that(#tableUtil.getKeys(self._globalMapsByModeAndLhs[mode]) == 0)
        assert.that(self._globalTrieByMode[mode]:isEmpty())
        assert.that(self._globalTrieByModeRaw[mode]:isEmpty())
        for _, bufInfo in pairs(self._bufferInfos) do
          assert.that(#tableUtil.getKeys(bufInfo.mapsByModeAndLhs[mode]) == 0)
          assert.that(bufInfo.triesByMode[mode]:isEmpty())
          assert.that(bufInfo.triesRawByMode[mode]:isEmpty())
        end
      end
      assert.that(#self._mapsById == 0)
      tableUtil.clear(self._bufferInfos)
      for _, map in pairs(self._commandMapsById) do
        map:removeFromVim()
      end
      tableUtil.clear(self._commandMapsById)
      tableUtil.clear(self._aliases)
      return log.debug("Successfully unmapped " .. tostring(count) .. " maps")
    end,
    addBufferMaps = function(self, arg1, arg2)
      local bufferHandle, func
      if arg2 == nil then
        bufferHandle = vim.api.nvim_get_current_buf()
        func = arg1
      else
        bufferHandle = arg1
        func = arg2
      end
      assert.that(type(func) == 'function', "Unexpected parameter type given")
      assert.that(self._bufferBlockHandle == nil, "Already in a call to vimp.addBufferMaps!  Must exit this first before attempting another.")
      self._bufferBlockHandle = bufferHandle
      local ok, retVal = pcall(func)
      assert.isEqual(self._bufferBlockHandle, bufferHandle)
      self._bufferBlockHandle = nil
      if not ok then
        return error(retVal, 2)
      end
    end,
    mapCommand = function(self, name, handler)
      assert.that(self._bufferBlockHandle == nil, "Buffer local commands are not currently supported")
      local id = self:_generateNewMappingId()
      local map = CommandMapInfo(id, handler, name)
      assert.that(self._commandMapsById[map.id] == nil)
      map:addToVim()
      self._commandMapsById[map.id] = map
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self._mapsById = { }
      self._mapsInProgress = { }
      self._commandMapsById = { }
      self._uniqueMapIdCount = 1
      self._aliases = { }
      self._globalMapsByModeAndLhs = { }
      self._globalTrieByMode = { }
      self._globalTrieByModeRaw = { }
      self._bufferInfos = { }
      self._mapErrorHandlingStrategy = MapErrorStrategies.logMinimalUserStackTrace
      self._bufferBlockHandle = nil
      self._fileLogStream = nil
      for _index_0 = 1, #AllModes do
        local m = AllModes[_index_0]
        self._globalMapsByModeAndLhs[m] = { }
        self._globalTrieByMode[m] = UniqueTrie()
        self._globalTrieByModeRaw[m] = UniqueTrie()
      end
      return self:_observeBufferUnload()
    end,
    __base = _base_0,
    __name = "Vimp"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Vimp = _class_0
end
_vimp = Vimp()
vimp = createVimpErrorWrapper()
return vimp
