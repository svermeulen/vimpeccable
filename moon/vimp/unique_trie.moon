
assert = require("vimp.util.assert")

-- Note here that lua does not support unicode and that strings are
-- ultimately just sequences of bytes
-- For example, lua strings like "ПРИВЕТ" have length 12 (moonscript returns 12 for #foo)
-- This is why we can safely use the string.byte function below
-- The nodes of the trie won't correspond to actual characters all the
-- time but I think it will still work
class UniqueTrie
  new: =>
    @root = {}

  is_empty: =>
    return next(@root) == nil

  _try_remove: (node, index, data) =>
    c = data\byte(index)
    child = node[c]

    if child == nil
      return false

    if index == #data
      -- Cannot remove because there's entries that have the given string as a prefix
      if next(child) != nil
        return false

      -- There is nothing after this so can remove
      node[c] = nil
      return true

    success = @\_try_remove(child, index + 1, data)

    if not success
      return false

    -- Only remove the branch nodes if we don't have other leaves
    if next(child) == nil
      node[c] = nil

    return success

  try_remove: (data) =>
    return @\_try_remove(@root, 1, data)

  _convert_bytes_to_string: (bytes) =>
    result = ''
    for c in *bytes
      result ..= string.char(c)
    return result

  _visit_branches: (node, stack, callback) =>
    for char, child in pairs(node)
      table.insert(stack, char)
      if next(child) != nil
        callback(@\_convert_bytes_to_string(stack))
        @\_visit_branches(child, stack, callback)
      table.remove(stack)

  visit_branches: (prefix, callback) =>
    node = @\_get_suffix_node(prefix)
    if node != nil
      @\_visit_branches(node, {}, callback)

  _visitSuffixes: (node, stack, callback) =>
    for char, child in pairs(node)
      table.insert(stack, char)
      if next(child) == nil
        callback(@\_convert_bytes_to_string(stack))
      else
        @\_visitSuffixes(child, stack, callback)
      table.remove(stack)

  _get_suffix_node: (prefix) =>
    currentNode = @root

    for i=1,#prefix
      c = prefix\byte(i)
      nextNode = currentNode[c]

      if not nextNode
        return nil

      currentNode = nextNode

    return currentNode

  visit_suffixes: (prefix, callback) =>
    node = @\_get_suffix_node(prefix)
    if node != nil
      @\_visitSuffixes(node, {}, callback)

  get_all_entries: =>
    return @\get_all_suffixes('')

  get_all_branches: (prefix) =>
    branches = {}
    @\visit_branches prefix, (suffix) ->
      table.insert(branches, suffix)
    return branches

  get_all_suffixes: (prefix) =>
    suffixes = {}
    @\visit_suffixes prefix, (suffix) ->
      table.insert(suffixes, suffix)
    return suffixes

  -- Adds the data to the trie
  -- Returns 0 on success, and otherwise returns the index
  -- where the conflict was encountered
  try_add: (data, dryRun) =>
    currentNode = @root
    isNew = false

    for i=1,#data
      c = data\byte(i)
      nextNode = currentNode[c]

      if nextNode and next(nextNode) == nil
        -- In this case, we do not add to the trie
        -- because this is a unique trie
        return false, data\sub(1, i), i == #data

      if not nextNode
        nextNode = {}
        isNew = true
        if not dryRun
          currentNode[c] = nextNode

      currentNode = nextNode

    if not isNew
      -- In this case, we are attempting to add a string
      -- that is a prefix of an existing entry, so do not add
      return false, data, false

    return true, nil, false

