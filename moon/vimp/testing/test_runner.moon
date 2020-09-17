
require('vimp')
string_util = require('vimp.util.string')
assert = require("vimp.util.assert")
log = require("vimp.util.log")
util = require("vimp.util.util")

class TestRunner
  _get_plugin_root_path: =>
    matches = [x for x in string.gmatch(vim.api.nvim_eval('&rtp'), "([^,]+)") when string_util.ends_with(x, '/vimpeccable')]
    assert.that(#matches == 1)
    return matches[1]

  _run_test_func: (func) =>
    start_tab = vim.api.nvim_get_current_tabpage()
    vim.cmd('normal! ' .. util.replace_special_chars("<c-w>v<c-w>T"))
    test_tab = vim.api.nvim_get_current_tabpage()
    buffer_handle = vim.api.nvim_create_buf(true, false)
    vim.cmd("b #{buffer_handle}")
    -- Always throw exceptions during testing
    vimp.map_error_handling_strategy = vimp.map_error_handling_strategies.none
    assert.that(vim.o.hidden, "Must set hidden property to run tests")

    action = ->
      func!
      vimp.unmap_all!

    success, ret_value = xpcall(action, debug.traceback)

    vim.api.nvim_set_current_tabpage(test_tab)
    vim.cmd('tabclose!')
    if vim.api.nvim_buf_is_loaded(buffer_handle)
      vim.cmd("bd! #{buffer_handle}")
    vim.api.nvim_set_current_tabpage(start_tab)

    -- Try this in case the error occurred during func!
    -- And just ignore any errors that occur
    -- We don't _just_ do this because we want the error from
    -- unmap_all to propagate if it gets that far
    -- This is nice because it will remove the maps from vim
    -- so we might not need to do a full restart to avoid getting
    -- errors if we run the tests again
    pcall(vimp.unmap_all)

    if not success
      error(ret_value, 2)

  _init_logging: =>
    -- vimp.enable_file_logging("debug", "~/Temp/vimpeccable.log")
    vimp.print_min_log_level = 'info'

  run_test_file: (file_path) =>
    @\_init_logging!
    success_count = @\_run_test_file(file_path)
    log.info("#{success_count} tests completed successfully")

  _run_test_file: (file_path) =>
    test_class = dofile(file_path)
    tester = test_class!
    log.info("Executing tests for file #{file_path}...")

    success_count = 0

    for methodName,func in pairs(getmetatable(tester))
      if string_util.startsWith(methodName, 'test')
        log.info("Executing test '#{methodName}' from file '#{file_path}'...")
        @\_run_test_func -> func(tester)
        success_count += 1

    return success_count

  run_test_method: (file_path, test_name) =>
    @\_init_logging!
    test_class = dofile(file_path)
    tester = test_class!
    log.info("Executing test '#{test_name}' from file '#{file_path}'...")
    @\_run_test_func ->
      tester[test_name](tester)
    log.info("Test #{test_name} completed successfully")

  run_all_tests: =>
    @\_init_logging!
    test_root = "#{@\_get_plugin_root_path!}/lua"

    success_count = 0
    for test_file in *vim.fn.globpath(test_root, '**/test_*.lua', 0, 1)
      success_count += @\_run_test_file(test_file)

    log.info("#{success_count} tests completed successfully")
