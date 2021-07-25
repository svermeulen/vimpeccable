local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local table_util = require("vimp.util.table")
local string_util = require("vimp.util.string")
local util = require("vimp.util.util")
local MapInfo = require("vimp.map_info")
local CommandMapInfo = require("vimp.command_map_info")
local create_vimp_error_wrapper = require("vimp.error_wrapper")
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
  log_message = 2,
  log_minimal_user_stack_trace = 3,
  log_user_stack_trace = 4,
  log_full_stack_trace = 5,
  rethrow_message = 6,
  none = 7
}
local Vimp
do
  local _class_0
  local _base_0 = {
    _get_all_maps = function(self)
      return self._maps_by_id
    end,
    _set_print_min_log_level = function(self, min_log_level)
      log.print_log_stream.min_log_level = log.convert_log_level_string_to_level(min_log_level)
    end,
    _set_map_context_provider = function(self, map_context_provider)
      self._map_context_provider = map_context_provider
    end,
    enable_file_logging = function(self, min_log_level, log_file_path)
      assert.that(self._file_log_stream == nil)
      self._file_log_stream = FileLogStream()
      self._file_log_stream:initialize(log.convert_log_level_string_to_level(min_log_level), log_file_path)
      return table.insert(log.streams, self._file_log_stream)
    end,
    show_all_maps = function(self, mode)
      return self:show_maps('', mode)
    end,
    _is_cancellation_map = function(self, map)
      return map.rhs == '<nop>' and string_util.ends_with(map.lhs, '<esc>')
    end,
    show_maps = function(self, prefix, mode)
      local prefixRaw = ''
      if prefix and #prefix > 0 then
        prefixRaw = vim.api.nvim_replace_termcodes(prefix, true, false, true)
      end
      mode = mode or 'n'
      assert.that(table_util.contains(AllModes, mode), "Invalid mode provided '" .. tostring(mode) .. "'")
      local result = { }
      self._global_trie_by_mode[mode]:visit_suffixes(prefixRaw, function(suffix)
        local mapping = self._global_maps_by_mode_and_lhs[mode][prefixRaw .. suffix]
        assert.that(mapping)
        if not self:_is_cancellation_map(mapping) then
          return table.insert(result, mapping)
        end
      end)
      local buf_info = self._buffer_infos[vim.api.nvim_get_current_buf()]
      if buf_info then
        buf_info.tries_by_mode[mode]:visit_suffixes(prefixRaw, function(suffix)
          local mapping = buf_info.maps_by_mode_and_lhs[mode][prefixRaw .. suffix]
          assert.that(mapping)
          if not self:_is_cancellation_map(mapping) then
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
          local action = mapping:get_rhs_display_text()
          output = output .. tostring(mapping.lhs) .. " -> " .. tostring(action) .. "\n"
        end
      end
      return vim.api.nvim_out_write(output .. '\n')
    end,
    _get_current_map_info = function(self)
      return self._maps_in_progress[#self._maps_in_progress]
    end,
    _get_maps_in_progress = function(self)
      return self._maps_in_progress
    end,
    _get_map_error_handling_strategies = function(self)
      return MapErrorStrategies
    end,
    _get_map_error_handling_strategy = function(self)
      return self._map_error_handling_strategy
    end,
    _set_map_error_handling_strategy = function(self, strategy)
      assert.that(strategy >= 1 and strategy <= 7, "Invalid map error handling strategy '" .. tostring(strategy) .. "'")
      self._map_error_handling_strategy = strategy
    end,
    _get_always_override = function(self)
      return self._always_override
    end,
    _set_always_override = function(self, always_override)
      assert.that(type(always_override) == 'boolean')
      self._always_override = always_override
    end,
    _observe_buffer_unload = function(self)
      vim.api.nvim_command([[augroup vimpBufWatch]])
      vim.api.nvim_command([[au!]])
      vim.api.nvim_command([[au BufUnload * lua _vimp:_on_buffer_unloaded()]])
      return vim.api.nvim_command([[augroup END]])
    end,
    _get_total_num_maps = function(self)
      local keys = table_util.get_keys(self._maps_by_id)
      return #keys
    end,
    _remove_mapping = function(self, map)
      map:remove_from_vim()
      self._maps_by_id[map.id] = nil
      local mode_maps, trie = self:_get_mode_maps_and_trie(map)
      assert.that(mode_maps[map.raw_lhs] ~= nil)
      mode_maps[map.raw_lhs] = nil
      if not map.extra_options.chord then
        local success = trie:try_remove(map.raw_lhs)
        return assert.that(success)
      end
    end,
    _on_buffer_unloaded = function(self)
      local buffer_handle = tonumber(vim.api.nvim_call_function("expand", {
        "<abuf>"
      }))
      return self:clear_buffer_maps(buffer_handle)
    end,
    _generate_new_mapping_id = function(self)
      self._unique_map_id_count = self._unique_map_id_count + 1
      return self._unique_map_id_count
    end,
    _validate_args = function(self, options, extra_options, lhs_list, rhs)
      assert.that(#lhs_list > 0)
      assert.that(type(rhs) == 'function' or type(rhs) == 'string', "Expected type 'function' or 'string' for rhs argument but instead found '" .. tostring(type(rhs)) .. "'")
      for _index_0 = 1, #lhs_list do
        local lhs = lhs_list[_index_0]
        assert.that(type(lhs) == 'string', "Expected type string for lhs argument but found '" .. tostring(type(lhs)) .. "'")
      end
    end,
    _convert_args = function(self, arg1, arg2, arg3, arg4)
      local modes, options_list, lhs, rhs
      if arg4 ~= nil then
        modes = arg1
        options_list = arg2
        lhs = arg3
        rhs = arg4
      else
        if arg3 ~= nil then
          if type(arg1) == 'table' then
            modes = 'n'
            options_list = arg1
          else
            modes = arg1
            options_list = { }
          end
          lhs = arg2
          rhs = arg3
        else
          options_list = { }
          modes = 'n'
          lhs = arg1
          rhs = arg2
        end
      end
      assert.that(type(options_list) == 'table', "Expected to find an options table but instead found: " .. tostring(options_list))
      if type(lhs) == 'string' then
        lhs = {
          lhs
        }
      end
      local options_map
      do
        local _tbl_0 = { }
        for _index_0 = 1, #options_list do
          local x = options_list[_index_0]
          if not ExtraOptions[x] then
            _tbl_0[x] = true
          end
        end
        options_map = _tbl_0
      end
      local extra_options_map
      do
        local _tbl_0 = { }
        for _index_0 = 1, #options_list do
          local x = options_list[_index_0]
          if ExtraOptions[x] then
            _tbl_0[x] = true
          end
        end
        extra_options_map = _tbl_0
      end
      return modes, options_map, extra_options_map, lhs, rhs
    end,
    _convert_command_args = function(self, arg1, arg2, arg3)
      local options, name, handler
      if arg3 ~= nil then
        options = arg1
        name = arg2
        handler = arg3
      else
        options = { }
        name = arg1
        handler = arg2
      end
      assert.that(type(options) == 'table', "Expected to find an options table but instead found: " .. tostring(options))
      return options, name, handler
    end,
    _executeCommandMap = function(self, mapId, userArgs)
      local map = self._command_maps_by_id[mapId]
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
      local map = self._maps_by_id[mapId]
      assert.that(map ~= nil)
      if not map.options.expr then
        if map.mode == 'x' then
          util.normal_bang('gv')
        elseif map.mode == 's' then
          util.normal_bang('gv<c-g>')
        end
      end
      assert.that(type(map.rhs) == 'function')
      table.insert(self._maps_in_progress, map)
      local success, result = xpcall(map.rhs, debug.traceback)
      assert.that(#self._maps_in_progress > 0)
      table.remove(self._maps_in_progress)
      if not success then
        error("Error when executing map '" .. tostring(map.lhs) .. "':\n" .. tostring(result) .. "\n")
      end
      if map.extra_options.repeatable then
        assert.that(not map.options.expr)
        vim.api.nvim_call_function('repeat#set', {
          map.raw_lhs
        })
      end
      if map.options.expr then
        return util.replace_special_chars(result)
      end
      return nil
    end,
    _addToTrieDryRun = function(self, trie, map, mapping_map)
      assert.that(not map.extra_options.chord)
      local succeeded, existing_prefix, exact_match = trie:try_add(map.raw_lhs, true)
      if succeeded then
        return true
      end
      assert.that(not exact_match)
      local conflict_map_infos = { }
      if #existing_prefix < #map.raw_lhs then
        local current_info = mapping_map[existing_prefix]
        assert.that(current_info)
        table.insert(conflict_map_infos, current_info)
      else
        assert.that(#existing_prefix == #map.raw_lhs)
        trie:visit_suffixes(map.raw_lhs, function(suffix)
          local current_info = mapping_map[map.raw_lhs .. suffix]
          assert.that(current_info)
          return table.insert(conflict_map_infos, current_info)
        end)
      end
      local conflict_output = string_util.join("\n", (function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #conflict_map_infos do
          local x = conflict_map_infos[_index_0]
          _accum_0[_len_0] = "    " .. tostring(x:to_string())
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
      return error("Map conflict found when attempting to add map:\n    " .. tostring(map:to_string()) .. "\nConflicts:\n" .. tostring(conflict_output))
    end,
    _new_buf_info = function(self)
      local buf_info = {
        maps_by_mode_and_lhs = { },
        tries_by_mode = { }
      }
      for _index_0 = 1, #AllModes do
        local m = AllModes[_index_0]
        buf_info.maps_by_mode_and_lhs[m] = { }
        buf_info.tries_by_mode[m] = UniqueTrie()
      end
      return buf_info
    end,
    addChordCancellations = function(self, ...)
      log.warning("Field 'vimp.addChordCancellations' is deprecated.  Use vimp.add_chord_cancellations instead!")
      return self:add_chord_cancellations(...)
    end,
    add_chord_cancellations = function(self, mode, prefix)
      assert.that(table_util.contains(AllModes, mode), "Invalid mode provided to add_chord_cancellations '" .. tostring(mode) .. "'")
      local trie
      if self._buffer_block_handle ~= nil then
        local buf_info = self._buffer_infos[vim.api.nvim_get_current_buf()]
        if buf_info == nil then
          return 
        end
        trie = buf_info.tries_by_mode[mode]
      else
        trie = self._global_trie_by_mode[mode]
      end
      local prefix_raw = vim.api.nvim_replace_termcodes(prefix, true, false, true)
      local escape_key = '<esc>'
      local escape_key_raw = vim.api.nvim_replace_termcodes(escape_key, true, false, true)
      local _list_0 = trie:get_all_branches(prefix_raw)
      for _index_0 = 1, #_list_0 do
        local suffix = _list_0[_index_0]
        if not string_util.ends_with(suffix, escape_key) and not string_util.ends_with(suffix, escape_key_raw) then
          self:bind(mode, prefix .. suffix .. escape_key, '<nop>')
        end
      end
    end,
    _get_mode_maps_and_trie = function(self, map)
      if map.buffer_handle ~= nil then
        local buf_info = self._buffer_infos[map.buffer_handle]
        if buf_info == nil then
          buf_info = self:_new_buf_info()
          self._buffer_infos[map.buffer_handle] = buf_info
        end
        return buf_info.maps_by_mode_and_lhs[map.mode], buf_info.tries_by_mode[map.mode]
      end
      return self._global_maps_by_mode_and_lhs[map.mode], self._global_trie_by_mode[map.mode]
    end,
    _add_mapping = function(self, map)
      local mode_maps, trie = self:_get_mode_maps_and_trie(map)
      local existing_map = mode_maps[map.raw_lhs]
      if existing_map then
        assert.that(map.extra_options.override or self._always_override, "Found duplicate mapping for keys '" .. tostring(map.lhs) .. "' in mode '" .. tostring(map.mode) .. "'.  Ignoring second attempt.\nCurrent Mapping: " .. tostring(existing_map:to_string()) .. "\nNew Mapping: " .. tostring(map:to_string()))
        self:_remove_mapping(existing_map)
      end
      local should_add_to_trie = not map.extra_options.chord
      if should_add_to_trie then
        self:_addToTrieDryRun(trie, map, mode_maps)
      end
      map:add_to_vim()
      self._maps_by_id[map.id] = map
      mode_maps[map.raw_lhs] = map
      if should_add_to_trie then
        local succeeded, existing_prefix, exact_match = trie:try_add(map.raw_lhs)
        return assert.that(succeeded)
      end
    end,
    _get_aliases = function(self)
      return self._aliases
    end,
    addAlias = function(self, ...)
      log.warning("Field 'vimp.addAlias' is deprecated.  Use vimp.add_alias instead!")
      return self:add_alias(...)
    end,
    add_alias = function(self, alias, replacement)
      assert.that(not self._aliases[alias], "Found multiple aliases with key '" .. tostring(alias) .. "'")
      self._aliases[alias] = replacement
    end,
    _apply_aliases = function(self, lhs)
      for k, v in pairs(self._aliases) do
        lhs = string_util.replace(lhs, k, v)
      end
      return lhs
    end,
    _create_map_info = function(self, mode, lhs, rhs, options, extra_options)
      log.debug("Adding " .. tostring(mode) .. " mode map: " .. tostring(lhs))
      local buffer_handle = self._buffer_block_handle
      if extra_options.buffer then
        assert.that(buffer_handle == nil, "Do not specify <buffer> option when inside a call to vimp.add_buffer_maps")
        buffer_handle = vim.api.nvim_get_current_buf()
      end
      if (not extra_options.override and not self._always_override) and buffer_handle == nil then
        options.unique = true
      end
      if extra_options.repeatable then
        assert.that(not options.expr, "Using <expr> along with <repeatable> is currently not supported")
        assert.that(mode == 'n', "The <repeatable> flag is currently only supported when using 'n' mode")
        if type(rhs) == 'string' then
          local rhs_str = rhs
          local rhs_str_noremap = options.noremap
          options.noremap = true
          rhs = function()
            if rhs_str_noremap then
              return util.normal_bang(rhs_str)
            else
              return util.rnormal(rhs_str)
            end
          end
        end
      end
      if type(rhs) == 'function' then
        options.silent = true
      end
      local id = self:_generate_new_mapping_id()
      assert.that(self._maps_by_id[id] == nil)
      local expanded_lhs = self:_apply_aliases(lhs)
      local raw_lhs = vim.api.nvim_replace_termcodes(expanded_lhs, true, false, true)
      return MapInfo(id, mode, options, extra_options, lhs, expanded_lhs, raw_lhs, rhs, buffer_handle, self:_try_get_map_context_info())
    end,
    _try_get_map_context_info = function(self)
      if self._map_context_provider ~= nil then
        return self:_map_context_provider()
      end
      return nil
    end,
    _expand_modes = function(self, modes)
      assert.that(#modes > 0, "Zero modes provided")
      local map = { }
      for i = 1, #modes do
        local mode = modes:sub(i, i)
        if mode == 'v' then
          map['x'] = 1
          map['s'] = 1
        elseif mode == 'l' then
          map['i'] = 1
          map['c'] = 1
        else
          assert.that(table_util.contains(AllModes, mode), "Invalid mode '" .. tostring(mode) .. "' provided in given mode list '" .. tostring(modes) .. "'")
          map[mode] = 1
        end
      end
      return table_util.get_keys(map)
    end,
    bind = function(self, ...)
      local modes, options, extra_options, lhs_list, rhs = self:_convert_args(...)
      local modeList = self:_expand_modes(modes)
      self:_validate_args(options, extra_options, lhs_list, rhs)
      assert.that(options.noremap == nil)
      options.noremap = true
      for _index_0 = 1, #lhs_list do
        local lhs = lhs_list[_index_0]
        for _index_1 = 1, #modeList do
          local mode = modeList[_index_1]
          local map = self:_create_map_info(mode, lhs, rhs, table_util.shallow_copy(options), table_util.shallow_copy(extra_options))
          self:_add_mapping(map)
        end
      end
    end,
    noremap = function(self, ...)
      return self:bind('nvo', ...)
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
      local modes, options, extra_options, lhs_list, rhs = self:_convert_args(...)
      local modeList = self:_expand_modes(modes)
      self:_validate_args(options, extra_options, lhs_list, rhs)
      assert.that(options.noremap == nil)
      for _index_0 = 1, #lhs_list do
        local lhs = lhs_list[_index_0]
        for _index_1 = 1, #modeList do
          local mode = modeList[_index_1]
          local map = self:_create_map_info(mode, lhs, rhs, table_util.shallow_copy(options), table_util.shallow_copy(extra_options))
          self:_add_mapping(map)
        end
      end
    end,
    map = function(self, ...)
      return self:rbind('nvo', ...)
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
    clearBufferMaps = function(self, ...)
      log.warning("Field 'vimp.clearBufferMaps' is deprecated.  Use vimp.clear_buffer_maps instead!")
      return self:clear_buffer_maps(...)
    end,
    clear_buffer_maps = function(self, buffer_handle)
      local buffer_maps
      do
        local _accum_0 = { }
        local _len_0 = 1
        for k, x in pairs(self._maps_by_id) do
          if x.buffer_handle == buffer_handle then
            _accum_0[_len_0] = x
            _len_0 = _len_0 + 1
          end
        end
        buffer_maps = _accum_0
      end
      if #buffer_maps == 0 then
        assert.that(self._buffer_infos[buffer_handle] == nil)
        return 
      end
      local buf_info = self._buffer_infos[buffer_handle]
      assert.that(buf_info)
      local count = 0
      for _index_0 = 1, #buffer_maps do
        local map = buffer_maps[_index_0]
        self:_remove_mapping(map)
        count = count + 1
      end
      self._buffer_infos[buffer_handle] = nil
    end,
    unmapAll = function(self, ...)
      log.warning("Field 'vimp.unmapAll' is deprecated.  Use vimp.unmap_all instead!")
      return self:unmap_all(...)
    end,
    unmap_all = function(self)
      log.debug("Unmapping all maps")
      local count = 0
      for _, map in pairs(self._maps_by_id) do
        self:_remove_mapping(map)
        count = count + 1
      end
      for _index_0 = 1, #AllModes do
        local mode = AllModes[_index_0]
        assert.that(#table_util.get_keys(self._global_maps_by_mode_and_lhs[mode]) == 0)
        assert.that(self._global_trie_by_mode[mode]:is_empty())
        for _, buf_info in pairs(self._buffer_infos) do
          assert.that(#table_util.get_keys(buf_info.maps_by_mode_and_lhs[mode]) == 0)
          assert.that(buf_info.tries_by_mode[mode]:is_empty())
        end
      end
      assert.that(#self._maps_by_id == 0)
      table_util.clear(self._buffer_infos)
      for _, map in pairs(self._command_maps_by_id) do
        map:remove_from_vim()
      end
      table_util.clear(self._command_maps_by_id)
      table_util.clear(self._aliases)
      return log.debug("Successfully unmapped " .. tostring(count) .. " maps")
    end,
    addBufferMaps = function(self, ...)
      log.warning("Field 'vimp.addBufferMaps' is deprecated.  Use vimp.add_buffer_maps instead!")
      return self:add_buffer_maps(...)
    end,
    add_buffer_maps = function(self, arg1, arg2)
      local buffer_handle, func
      if arg2 == nil then
        buffer_handle = vim.api.nvim_get_current_buf()
        func = arg1
      else
        buffer_handle = arg1
        func = arg2
      end
      assert.that(type(func) == 'function', "Unexpected parameter type given")
      assert.that(self._buffer_block_handle == nil, "Already in a call to vimp.add_buffer_maps!  Must exit this first before attempting another.")
      self._buffer_block_handle = buffer_handle
      local ok, ret_val = xpcall(func, debug.traceback)
      assert.is_equal(self._buffer_block_handle, buffer_handle)
      self._buffer_block_handle = nil
      if not ok then
        return log.error("Error when calling 'vimp.add_buffer_maps': " .. tostring(ret_val))
      end
    end,
    mapCommand = function(self, ...)
      log.warning("Field 'vimp.mapCommand' is deprecated.  Use vimp.map_command instead!")
      return self:map_command(...)
    end,
    map_command = function(self, ...)
      local options, name, handler = self:_convert_command_args(...)
      assert.that(self._buffer_block_handle == nil, "Buffer local commands are not currently supported")
      local id = self:_generate_new_mapping_id()
      local map = CommandMapInfo(id, handler, name, options)
      assert.that(self._command_maps_by_id[map.id] == nil)
      map:add_to_vim()
      self._command_maps_by_id[map.id] = map
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self._maps_by_id = { }
      self._maps_in_progress = { }
      self._command_maps_by_id = { }
      self._unique_map_id_count = 1
      self._aliases = { }
      self._global_maps_by_mode_and_lhs = { }
      self._global_trie_by_mode = { }
      self._buffer_infos = { }
      self._map_error_handling_strategy = MapErrorStrategies.log_minimal_user_stack_trace
      self._buffer_block_handle = nil
      self._file_log_stream = nil
      self._map_context_provider = nil
      self._always_override = false
      for _index_0 = 1, #AllModes do
        local m = AllModes[_index_0]
        self._global_maps_by_mode_and_lhs[m] = { }
        self._global_trie_by_mode[m] = UniqueTrie()
      end
      return self:_observe_buffer_unload()
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
vimp = create_vimp_error_wrapper()
return vimp
