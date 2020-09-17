
class Util
  replace_special_chars: (str) ->
    return vim.api.nvim_replace_termcodes(str, true, false, true)

  -- Similar to vim.cmd('normal! x')
  normal_bang: (keys) ->
    vim.api.nvim_feedkeys(
      Util.replace_special_chars(keys), 'nx', true)

  -- recursive version of normal
  -- aka vim.cmd('normal x')
  rnormal: (keys) ->
    vim.api.nvim_feedkeys(
      Util.replace_special_chars(keys), 'mx', true)

