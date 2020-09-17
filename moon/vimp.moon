
assert = require("vimp.util.assert")
log = require("vimp.util.log")
table_util = require("vimp.util.table")
string_util = require("vimp.util.string")
util = require("vimp.util.util")
MapInfo = require("vimp.map_info")
CommandMapInfo = require("vimp.command_map_info")
create_vimp_error_wrapper = require("vimp.error_wrapper")
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
  log_message: 2
  log_minimal_user_stack_trace: 3
  log_user_stack_trace: 4
  log_full_stack_trace: 5
  rethrow_message: 6
  none: 7

class Vimp
  new: =>
    @_maps_by_id = {}
    @_maps_in_progress = {}
    @_command_maps_by_id = {}
    @_unique_map_id_count = 1
    @_aliases = {}
    @_global_maps_by_mode_and_lhs = {}
    @_global_trie_by_mode = {}
    @_global_trie_by_mode_raw = {}
    @_buffer_infos = {}
    @_map_error_handling_strategy = MapErrorStrategies.log_minimal_user_stack_trace
    @_buffer_block_handle = nil
    @_file_log_stream = nil

    for m in *AllModes
      @_global_maps_by_mode_and_lhs[m] = {}
      @_global_trie_by_mode[m] = UniqueTrie()
      @_global_trie_by_mode_raw[m] = UniqueTrie()

    @\_observe_buffer_unload!

  _set_print_min_log_level: (min_log_level) =>
    log.print_log_stream.min_log_level = log.convert_log_level_string_to_level(min_log_level)

  enable_file_logging: (min_log_level, log_file_path) =>
    assert.that(@_file_log_stream == nil)
    @_file_log_stream = FileLogStream()
    @_file_log_stream\initialize(
      log.convert_log_level_string_to_level(min_log_level), log_file_path)
    table.insert(log.streams, @_file_log_stream)

  -- Use var args to work with commands
  show_all_maps: (mode) =>
    @\show_maps('', mode)

  _is_cancellation_map: (map) =>
    return map.rhs == '<nop>' and string_util.ends_with(map.lhs, '<esc>')

  show_maps: (prefix, mode) =>
    mode = mode or 'n'
    assert.that(table_util.contains(AllModes, mode),
      "Invalid mode provided '#{mode}'")
    result = {}
    @_global_trie_by_mode[mode]\visit_suffixes prefix, (suffix) ->
      mapping = @_global_maps_by_mode_and_lhs[mode][prefix .. suffix]
      assert.that(mapping)
      if not @\_is_cancellation_map(mapping)
        table.insert(result, mapping)

    buf_info = @_buffer_infos[vim.api.nvim_get_current_buf()]
    if buf_info
      buf_info.tries_by_mode[mode]\visit_suffixes prefix, (suffix) ->
        mapping = buf_info.maps_by_mode_and_lhs[mode][prefix .. suffix]
        assert.that(mapping)
        if not @\_is_cancellation_map(mapping)
          table.insert(result, mapping)

    output = "Maps for prefix '#{prefix}' (mode #{mode}):\n"
    if #result == 0
      output ..= "<None>"
    else
      table.sort(result, (left, right) -> left.lhs < right.lhs)
      for mapping in *result
        action = mapping\get_rhs_display_text!
        output ..= "#{mapping.lhs} -> #{action}\n"
    vim.api.nvim_out_write(output .. '\n')

  _get_current_map_info: =>
    return @_maps_in_progress[#@_maps_in_progress]

  _get_maps_in_progress: =>
    return @_maps_in_progress

  _get_map_error_handling_strategies: =>
    return MapErrorStrategies

  _get_map_error_handling_strategy: =>
    return @_map_error_handling_strategy

  _set_map_error_handling_strategy: (strategy) =>
    assert.that(strategy >= 1 and strategy <= 7, "Invalid map error handling strategy '#{strategy}'")
    @_map_error_handling_strategy = strategy

  _observe_buffer_unload: =>
    -- Note that we want to use BufUnload here and not BufDelete because BufDelete
    -- does not get triggered for unlisted buffers
    vim.api.nvim_command [[augroup vimpBufWatch]]
    vim.api.nvim_command [[au!]]
    vim.api.nvim_command [[au BufUnload * lua _vimp:_onBufferUnloaded()]]
    vim.api.nvim_command [[augroup END]]

  -- Note that this includes both buffer local maps and global maps
  _get_total_num_maps: =>
    keys = table_util.get_keys(@_maps_by_id)
    return #keys

  _remove_mapping: (map) =>
    -- Remove from vim first in case it fails
    map\remove_from_vim!
    @_maps_by_id[map.id] = nil

    mode_maps, trie, trie_raw = @\_get_mode_maps_and_trie(map)

    assert.that(mode_maps[map.lhs] != nil)
    mode_maps[map.lhs] = nil

    if not map.extra_options.chord
      success = trie\try_remove(map.lhs)
      assert.that(success)

      success = trie_raw\try_remove(map.raw_lhs)
      assert.that(success)

  _onBufferUnloaded: =>
    buffer_handle = tonumber(vim.api.nvim_call_function("expand", {"<abuf>"}))
    @\clear_buffer_maps(buffer_handle)

  _generate_new_mapping_id: =>
    @_unique_map_id_count += 1
    return @_unique_map_id_count

  _validate_args: (modes, options, extra_options, lhs_list, rhs) =>
    assert.that(#lhs_list > 0)
    assert.that(#modes > 0, "Zero modes provided")

    assert.that(type(rhs) == 'function' or type(rhs) == 'string',
      "Expected type 'function' or 'string' for rhs argument but instead found '#{type(rhs)}'")

    for lhs in *lhs_list
      assert.that(type(lhs) == 'string',
        "Expected type string for lhs argument but found '#{type(lhs)}'")

    for i = 1, #modes
      mode = modes\sub(i, i)
      assert.that(table_util.contains(AllModes, mode), "Invalid mode provided: '#{modes}'")

  -- 4 params = modes, options, lhs, rhs
  -- 3 params = (when string) modes, lhs, rhs
  -- 3 params = (when table) options, lhs, rhs
  -- 2 params = lhs, rhs
  _convert_args: (arg1, arg2, arg3, arg4) =>
    local modes, options_list, lhs, rhs

    if arg4 != nil
      modes = arg1
      options_list = arg2
      lhs = arg3
      rhs = arg4
    else if arg3 != nil
      if type(arg1) == 'table'
        modes = 'n'
        options_list = arg1
      else
        modes = arg1
        options_list = {}
      lhs = arg2
      rhs = arg3
    else
      options_list = {}
      modes = 'n'
      lhs = arg1
      rhs = arg2

    assert.that(type(options_list) == 'table', "Expected to find an options table but instead found: #{options_list}")

    if type(lhs) == 'string'
      lhs = {lhs}

    options_map = {x,true for x in *options_list when not ExtraOptions[x]}
    extra_options_map = {x,true for x in *options_list when ExtraOptions[x]}

    return modes, options_map, extra_options_map, lhs, rhs

  _executeCommandMap: (mapId, userArgs) =>
    map = @_command_maps_by_id[mapId]

    assert.that(map != nil)

    action = ->
      map.handler(unpack(userArgs))

    -- Call user function and get the full stack trace if error occurs
    success, result = xpcall(action, debug.traceback)

    if not success
      -- Always rethrow on errors
      error("Error when executing command '#{map.name}': #{result}\n")

  _executeMap: (mapId) =>
    map = @_maps_by_id[mapId]

    assert.that(map != nil)

    if not map.options.expr
      if map.mode == 'x'
        util.normal_bang('gv')
      elseif map.mode == 's'
        util.normal_bang('gv<c-g>')

    assert.that(type(map.rhs) == 'function')

    table.insert(@_maps_in_progress, map)
    -- Call user function and get the full stack trace if error occurs
    success, result = xpcall(map.rhs, debug.traceback)
    -- Remove the last element
    assert.that(#@_maps_in_progress > 0)
    table.remove(@_maps_in_progress)

    if not success
      -- Always rethrow on errors
      error("Error when executing map '#{map.lhs}': #{result}\n")

    if map.extra_options.repeatable
      assert.that(not map.options.expr)
      vim.api.nvim_call_function('repeat#set', {util.replace_special_chars(map.lhs)})

    if map.options.expr
      -- This appears to be necessary even though I would expect
      -- vim to handle this for us
      return util.replace_special_chars(result)

    return nil

  _addToTrieDryRun: (trie, map, mapping_map) =>
    assert.that(not map.extra_options.chord)

    succeeded, existing_prefix, exact_match = trie\try_add(map.lhs, true)

    if succeeded
      return true

    -- This should never happen because we check for duplicates before this
    assert.that(not exact_match)

    conflict_map_infos = {}

    if #existing_prefix < #map.lhs
      -- In this case, the existing_prefix must match an actual map
      -- otherwise, the prefix would be a branch and therefore the
      -- add would have succeeded
      current_info = mapping_map[existing_prefix]
      assert.that(current_info)
      table.insert(conflict_map_infos, current_info)
    else
      assert.that(#existing_prefix == #map.lhs)

      trie\visit_suffixes map.lhs, (suffix) ->
        current_info = mapping_map[map.lhs .. suffix]
        assert.that(current_info)
        table.insert(conflict_map_infos, current_info)

    conflict_output = string_util.join("\n", ["    #{x\to_string!}" for x in *conflict_map_infos])
    error("Map conflict found when attempting to add map:\n    #{map\to_string!}\nConflicts:\n#{conflict_output}")

  _new_buf_info: =>
    buf_info = {maps_by_mode_and_lhs: {}, tries_by_mode: {}, tries_raw_by_mode: {}}

    for m in *AllModes
      buf_info.maps_by_mode_and_lhs[m] = {}
      buf_info.tries_by_mode[m] = UniqueTrie()
      buf_info.tries_raw_by_mode[m] = UniqueTrie()

    return buf_info

  add_chord_cancellations: (mode, prefix) =>
    assert.that(table_util.contains(AllModes, mode),
      "Invalid mode provided to add_chord_cancellations '#{mode}'")
    local trie_raw
    if @_buffer_block_handle != nil
      buf_info = @_buffer_infos[vim.api.nvim_get_current_buf()]
      if buf_info == nil
        return
      trie_raw = buf_info.tries_raw_by_mode[mode]
    else
      trie_raw = @_global_trie_by_mode_raw[mode]
    prefix_raw = vim.api.nvim_replace_termcodes(prefix, true, false, true)
    escape_key = '<esc>'
    escape_key_raw = vim.api.nvim_replace_termcodes(escape_key, true, false, true)

    -- Note here that we have to use get_all_branches instead of visit_branches because
    -- otherwise we get into an infinite loop
    for suffix in *trie_raw\get_all_branches(prefix_raw)
      -- This check might not be necessary but better to be safe
      if not string_util.ends_with(suffix, escape_key) and not string_util.ends_with(suffix, escape_key_raw)
        -- Suffix here is raw but that should be ok
        @\bind(mode, prefix .. suffix .. escape_key, '<nop>')

  _get_mode_maps_and_trie: (map) =>
    if map.buffer_handle != nil
      buf_info = @_buffer_infos[map.buffer_handle]

      if buf_info == nil
        buf_info = @\_new_buf_info!
        @_buffer_infos[map.buffer_handle] = buf_info

      return buf_info.maps_by_mode_and_lhs[map.mode], buf_info.tries_by_mode[map.mode], buf_info.tries_raw_by_mode[map.mode]

    return @_global_maps_by_mode_and_lhs[map.mode], @_global_trie_by_mode[map.mode], @_global_trie_by_mode_raw[map.mode]

  _add_mapping: (map) =>
    mode_maps, trie, trie_raw = @\_get_mode_maps_and_trie(map)

    existing_map = mode_maps[map.lhs]

    if existing_map
      assert.that(map.extra_options.override,
        "Found duplicate mapping for keys '#{map.lhs}' in mode '#{map.mode}'.  Ignoring second attempt.  Current Mapping: #{existing_map\get_rhs_display_text!}, New Mapping: #{map\get_rhs_display_text!}")

      @\_remove_mapping(existing_map)

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
    should_add_to_trie = not map.extra_options.chord

    if should_add_to_trie
      @\_addToTrieDryRun(trie, map, mode_maps)

    map\add_to_vim!
    -- Now that add_to_vim has succeeded, we can store the mapping
    -- We need to wait until after this point in case there's errors
    -- (eg. duplicate map)

    @_maps_by_id[map.id] = map
    mode_maps[map.lhs] = map

    if should_add_to_trie
      succeeded, existing_prefix, exact_match = trie\try_add(map.lhs)
      assert.that(succeeded)

      succeeded, existing_prefix, exact_match = trie_raw\try_add(map.raw_lhs)
      assert.that(succeeded)

  _get_aliases: =>
    return @_aliases

  add_alias: (alias, replacement) =>
    assert.that(not @_aliases[alias], "Found multiple aliases with key '#{alias}'")
    @_aliases[alias] = replacement

  _apply_aliases: (lhs) =>
    for k,v in pairs(@_aliases)
      lhs = string_util.replace(lhs, k, v)
    return lhs

  _create_map_info: (mode, lhs, rhs, options, extra_options) =>
    log.debug("Adding #{mode} mode map: #{lhs}")

    buffer_handle = @_buffer_block_handle

    if extra_options.buffer
      assert.that(buffer_handle == nil, "Do not specify <buffer> option when inside a call to vimp.add_buffer_maps")
      buffer_handle = vim.api.nvim_get_current_buf()

    -- Do not use <unique> for buffer maps because it's very common to override global maps with buffer ones
    -- When extra_options.override option is not provided, it will still make sure it doesn't collide with
    --  other buffer local ones
    if not extra_options.override and buffer_handle == nil
      options.unique = true

    if extra_options.repeatable
      assert.that(not options.expr, "Using <expr> along with <repeatable> is currently not supported")
      assert.that(mode == 'n', "The <repeatable> flag is currently only supported when using 'n' mode")

      if type(rhs) == 'string'
        -- In this case we need to make it into a lua function so that our execute map function gets calls and we call repeat#set
        rhs_str = rhs
        rhs_str_noremap = options.noremap
        -- lua functions are always noremap
        options.noremap = true
        rhs = ->
          if rhs_str_noremap
            util.normal_bang(rhs_str)
          else
            util.rnormal(rhs_str)

    if type(rhs) == 'function'
      -- Neccessary to avoid printing out ':lua _vimp:_executeMap(146)' every time
      options.silent = true

    id = @\_generate_new_mapping_id!
    assert.that(@_maps_by_id[id] == nil)

    expanded_lhs = @\_apply_aliases(lhs)
    raw_lhs = vim.api.nvim_replace_termcodes(expanded_lhs, true, false, true)

    return MapInfo(
      id, mode, options, extra_options, lhs, expanded_lhs, raw_lhs, rhs, buffer_handle)

  bind: (...) =>
    modes, options, extra_options, lhs_list, rhs = @\_convert_args(...)
    -- Validate seperately because error_wrapper uses _convert_args
    @\_validate_args(modes, options, extra_options, lhs_list, rhs)
    assert.that(options.noremap == nil)
    options.noremap = true
    for lhs in *lhs_list
      for i = 1, #modes
        mode = modes\sub(i, i)
        map = @\_create_map_info(
          mode, lhs, rhs, table_util.shallow_copy(options), table_util.shallow_copy(extra_options))
        @\_add_mapping(map)

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
    modes, options, extra_options, lhs_list, rhs = @\_convert_args(...)
    -- Validate seperately because error_wrapper uses _convert_args
    @\_validate_args(modes, options, extra_options, lhs_list, rhs)
    assert.that(options.noremap == nil)
    for lhs in *lhs_list
      for i = 1, #modes
        mode = modes\sub(i, i)
        map = @\_create_map_info(
          mode, lhs, rhs, table_util.shallow_copy(options), table_util.shallow_copy(extra_options))
        @\_add_mapping(map)

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

  clear_buffer_maps: (buffer_handle) =>
    -- Store it first since we are removing from _maps_by_id at the same time
    buffer_maps = [x for k, x in pairs(@_maps_by_id) when x.buffer_handle == buffer_handle]

    if #buffer_maps == 0
      assert.that(@_buffer_infos[buffer_handle] == nil)
      return

    buf_info = @_buffer_infos[buffer_handle]
    assert.that(buf_info)

    count = 0
    for map in *buffer_maps
      @\_remove_mapping(map)
      count += 1

    @_buffer_infos[buffer_handle] = nil

    -- log.debug("Removed #{count} maps for #{buffer_handle}")

  unmap_all: =>
    log.debug("Unmapping all maps")

    count = 0
    for _, map in pairs(@_maps_by_id)
      @\_remove_mapping(map)
      count += 1

    for mode in *AllModes
      assert.that(#table_util.get_keys(@_global_maps_by_mode_and_lhs[mode]) == 0)
      assert.that(@_global_trie_by_mode[mode]\is_empty!)
      assert.that(@_global_trie_by_mode_raw[mode]\is_empty!)

      for _, buf_info in pairs(@_buffer_infos)
        assert.that(#table_util.get_keys(buf_info.maps_by_mode_and_lhs[mode]) == 0)
        assert.that(buf_info.tries_by_mode[mode]\is_empty!)
        assert.that(buf_info.tries_raw_by_mode[mode]\is_empty!)

    assert.that(#@_maps_by_id == 0)

    table_util.clear(@_buffer_infos)

    for _, map in pairs(@_command_maps_by_id)
      map\remove_from_vim!

    table_util.clear(@_command_maps_by_id)
    table_util.clear(@_aliases)

    -- Don't bother resetting _unique_map_id_count to be extra safe
    log.debug("Successfully unmapped #{count} maps")

  -- Can either be called with a callback only (in which case it uses
  -- current buffer) or with a bufferhandle first then the callback
  add_buffer_maps: (arg1, arg2) =>
    local buffer_handle, func
    if arg2 == nil
      buffer_handle = vim.api.nvim_get_current_buf()
      func = arg1
    else
      buffer_handle = arg1
      func = arg2
    assert.that(type(func) == 'function', "Unexpected parameter type given")
    assert.that(@_buffer_block_handle == nil, "Already in a call to vimp.add_buffer_maps!  Must exit this first before attempting another.")
    @_buffer_block_handle = buffer_handle
    ok, ret_val = pcall(func)
    assert.is_equal(@_buffer_block_handle, buffer_handle)
    @_buffer_block_handle = nil

    if not ok
      error(ret_val, 2)

  map_command: (name, handler) =>
    assert.that(@_buffer_block_handle == nil, "Buffer local commands are not currently supported")

    id = @\_generate_new_mapping_id!
    map = CommandMapInfo(id, handler, name)
    assert.that(@_command_maps_by_id[map.id] == nil)
    map\add_to_vim!
    @_command_maps_by_id[map.id] = map

export vimp, _vimp
_vimp = Vimp()
vimp = create_vimp_error_wrapper!
return vimp
