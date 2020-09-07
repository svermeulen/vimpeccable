
assert = require("vimp.util.assert")

class UniqueTrie
  new: =>
    @root = {}

  _remove: (node, index, data) =>
    c = data\byte(index)
    child = node[c]
    assert.that(child)
    if index < #data
      @\_remove(child, index + 1, data)
    if next(child) == nil
      node[c] = nil

  remove: (data) =>
    @\_remove(@root, 1, data)

  _convertBytesToString: (bytes) =>
    result = ''
    for c in *bytes
      result ..= string.char(c)
    return result

  _visitSuffixes: (node, stack, callback) =>
    for char, child in pairs(node)
      table.insert(stack, char)
      if next(child) == nil
        callback(@\_convertBytesToString(stack))
      else
        @\_visitSuffixes(child, stack, callback)
      table.remove(stack)

  _getSuffixNode: (prefix) =>
    currentNode = @root

    for i=1,#prefix
      c = prefix\byte(i)
      nextNode = currentNode[c]

      if not nextNode
        return nil

      currentNode = nextNode

    return currentNode

  _visitBranches: (node, stack, callback) =>
    for char, child in pairs(node)
      table.insert(stack, char)
      if next(child) != nil
        callback(@\_convertBytesToString(stack))
        @\_visitBranches(child, stack, callback)
      table.remove(stack)

  visitBranches: (prefix, callback) =>
    node = @\_getSuffixNode(prefix)
    if node != nil
      @\_visitBranches(node, {}, callback)

  visitSuffixes: (prefix, callback) =>
    node = @\_getSuffixNode(prefix)
    if node != nil
      @\_visitSuffixes(node, {}, callback)

  -- Adds the data to the trie
  -- Returns 0 on success, and otherwise returns the index
  -- where the conflict was encountered
  tryAdd: (data) =>
    currentNode = @root
    isNew = false

    for i=1,#data
      c = data\byte(i)
      nextNode = currentNode[c]

      if nextNode and next(nextNode) == nil
        return false, data\sub(1, i), i == #data

      if not nextNode
        nextNode = {}
        isNew = true
        currentNode[c] = nextNode

      currentNode = nextNode

    if not isNew
      return false, data, false

    return true, nil, false

