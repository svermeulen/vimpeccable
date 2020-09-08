
class Util
  replaceSpecialChars: (str) ->
    return vim.api.nvim_replace_termcodes(str, true, false, true)

  -- Similar to vim.cmd('normal! x')
  normalBang: (keys) ->
    vim.api.nvim_feedkeys(
      Util.replaceSpecialChars(keys), 'nx', true)

  -- recursive version of normal
  -- aka vim.cmd('normal x')
  rnormal: (keys) ->
    vim.api.nvim_feedkeys(
      Util.replaceSpecialChars(keys), 'mx', true)

