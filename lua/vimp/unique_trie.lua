local assert = require("vimp.util.assert")
local UniqueTrie
do
  local _class_0
  local _base_0 = {
    is_empty = function(self)
      return next(self.root) == nil
    end,
    _try_remove = function(self, node, index, data)
      local c = data:byte(index)
      local child = node[c]
      if child == nil then
        return false
      end
      if index == #data then
        if next(child) ~= nil then
          return false
        end
        node[c] = nil
        return true
      end
      local success = self:_try_remove(child, index + 1, data)
      if not success then
        return false
      end
      if next(child) == nil then
        node[c] = nil
      end
      return success
    end,
    try_remove = function(self, data)
      return self:_try_remove(self.root, 1, data)
    end,
    _convert_bytes_to_string = function(self, bytes)
      local result = ''
      for _index_0 = 1, #bytes do
        local c = bytes[_index_0]
        result = result .. string.char(c)
      end
      return result
    end,
    _visit_branches = function(self, node, stack, callback)
      for char, child in pairs(node) do
        table.insert(stack, char)
        if next(child) ~= nil then
          callback(self:_convert_bytes_to_string(stack))
          self:_visit_branches(child, stack, callback)
        end
        table.remove(stack)
      end
    end,
    visit_branches = function(self, prefix, callback)
      local node = self:_get_suffix_node(prefix)
      if node ~= nil then
        return self:_visit_branches(node, { }, callback)
      end
    end,
    _visitSuffixes = function(self, node, stack, callback)
      for char, child in pairs(node) do
        table.insert(stack, char)
        if next(child) == nil then
          callback(self:_convert_bytes_to_string(stack))
        else
          self:_visitSuffixes(child, stack, callback)
        end
        table.remove(stack)
      end
    end,
    _get_suffix_node = function(self, prefix)
      local currentNode = self.root
      for i = 1, #prefix do
        local c = prefix:byte(i)
        local nextNode = currentNode[c]
        if not nextNode then
          return nil
        end
        currentNode = nextNode
      end
      return currentNode
    end,
    visit_suffixes = function(self, prefix, callback)
      local node = self:_get_suffix_node(prefix)
      if node ~= nil then
        return self:_visitSuffixes(node, { }, callback)
      end
    end,
    get_all_entries = function(self)
      return self:get_all_suffixes('')
    end,
    get_all_branches = function(self, prefix)
      local branches = { }
      self:visit_branches(prefix, function(suffix)
        return table.insert(branches, suffix)
      end)
      return branches
    end,
    get_all_suffixes = function(self, prefix)
      local suffixes = { }
      self:visit_suffixes(prefix, function(suffix)
        return table.insert(suffixes, suffix)
      end)
      return suffixes
    end,
    try_add = function(self, data, dryRun)
      local currentNode = self.root
      local isNew = false
      for i = 1, #data do
        local c = data:byte(i)
        local nextNode = currentNode[c]
        if nextNode and next(nextNode) == nil then
          return false, data:sub(1, i), i == #data
        end
        if not nextNode then
          nextNode = { }
          isNew = true
          if not dryRun then
            currentNode[c] = nextNode
          end
        end
        currentNode = nextNode
      end
      if not isNew then
        return false, data, false
      end
      return true, nil, false
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self.root = { }
    end,
    __base = _base_0,
    __name = "UniqueTrie"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  UniqueTrie = _class_0
  return _class_0
end
