local Util
do
  local _class_0
  local _base_0 = {
    replaceSpecialChars = function(str)
      return vim.api.nvim_replace_termcodes(str, true, false, true)
    end,
    normalBang = function(keys)
      return vim.api.nvim_feedkeys(Util.replaceSpecialChars(keys), 'nx', true)
    end,
    rnormal = function(keys)
      return vim.api.nvim_feedkeys(Util.replaceSpecialChars(keys), 'mx', true)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Util"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Util = _class_0
  return _class_0
end
