local assert = require("vimp.util.assert")
local UniqueTrie
do
  local _class_0
  local _base_0 = {
    isEmpty = function(self)
      return next(self.root) == nil
    end,
    _tryRemove = function(self, node, index, data)
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
      local success = self:_tryRemove(child, index + 1, data)
      if not success then
        return false
      end
      if next(child) == nil then
        node[c] = nil
      end
      return success
    end,
    tryRemove = function(self, data)
      return self:_tryRemove(self.root, 1, data)
    end,
    _convertBytesToString = function(self, bytes)
      local result = ''
      for _index_0 = 1, #bytes do
        local c = bytes[_index_0]
        result = result .. string.char(c)
      end
      return result
    end,
    _visitBranches = function(self, node, stack, callback)
      for char, child in pairs(node) do
        table.insert(stack, char)
        if next(child) ~= nil then
          callback(self:_convertBytesToString(stack))
          self:_visitBranches(child, stack, callback)
        end
        table.remove(stack)
      end
    end,
    visitBranches = function(self, prefix, callback)
      local node = self:_getSuffixNode(prefix)
      if node ~= nil then
        return self:_visitBranches(node, { }, callback)
      end
    end,
    _visitSuffixes = function(self, node, stack, callback)
      for char, child in pairs(node) do
        table.insert(stack, char)
        if next(child) == nil then
          callback(self:_convertBytesToString(stack))
        else
          self:_visitSuffixes(child, stack, callback)
        end
        table.remove(stack)
      end
    end,
    _getSuffixNode = function(self, prefix)
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
    visitSuffixes = function(self, prefix, callback)
      local node = self:_getSuffixNode(prefix)
      if node ~= nil then
        return self:_visitSuffixes(node, { }, callback)
      end
    end,
    getAllEntries = function(self)
      return self:getAllSuffixes('')
    end,
    getAllBranches = function(self, prefix)
      local branches = { }
      self:visitBranches(prefix, function(suffix)
        return table.insert(branches, suffix)
      end)
      return branches
    end,
    getAllSuffixes = function(self, prefix)
      local suffixes = { }
      self:visitSuffixes(prefix, function(suffix)
        return table.insert(suffixes, suffix)
      end)
      return suffixes
    end,
    tryAdd = function(self, data, dryRun)
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
