
assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")
UniqueTrie = require("vimp.unique_trie")

hasSameContents = (list1, list2) ->
  if #list1 != #list2
    return false

  map1 = {x,true for x in *list1}

  for item in *list2
    if map1[item] == nil
      return false

  return true

assertSameContents = (list1, list2) ->
  assert.that(hasSameContents(list1, list2), "Expected '#{vim.inspect(list1)}' to equal '#{vim.inspect(list2)}'")

class Tester

  testAdds: =>
    trie = UniqueTrie()

    succeeded, existingPrefix, exactMatch = trie\tryAdd('abc')
    assert.that(succeeded)
    assert.that(existingPrefix == nil)
    assert.that(not exactMatch)

    succeeded, existingPrefix, exactMatch = trie\tryAdd('abc')
    assert.that(not succeeded)
    assert.that(existingPrefix == 'abc')
    assert.that(exactMatch)

    succeeded, existingPrefix, exactMatch = trie\tryAdd('abcd')
    assert.that(not succeeded)
    assert.that(existingPrefix == 'abc')
    assert.that(not exactMatch)

    -- We can share prefixes with other entries, but each prefix
    -- must not be an entire other entry
    succeeded, existingPrefix, exactMatch = trie\tryAdd('abxyz')
    assert.that(succeeded)
    assert.that(existingPrefix == nil)
    assert.that(not exactMatch)

    succeeded, existingPrefix, exactMatch = trie\tryAdd('a')
    assert.that(not succeeded)
    assert.that(existingPrefix == 'a')
    assert.that(not exactMatch)

    -- Note that they are the full matches here
    assertSameContents(trie\getAllEntries(), {'abc', 'abxyz'})
    assertSameContents(trie\getAllSuffixes(''), {'abc', 'abxyz'})
    assertSameContents(trie\getAllSuffixes('a'), {'bc', 'bxyz'})
    assertSameContents(trie\getAllSuffixes('ab'), {'c', 'xyz'})
    assertSameContents(trie\getAllSuffixes('abc'), {})

  testRemove: =>
    trie = UniqueTrie()
    succeeded, existingPrefix, exactMatch = trie\tryAdd('ab')
    assert.that(succeeded)
    assertSameContents(trie\getAllEntries(), {'ab'})
    assert.that(not trie\tryRemove('a'))
    assert.that(trie\tryRemove('ab'))
    assertSameContents(trie\getAllEntries(), {})
    succeeded, existingPrefix, exactMatch = trie\tryAdd('ab')
    assert.that(succeeded)
    succeeded, existingPrefix, exactMatch = trie\tryAdd('acdef')
    assert.that(succeeded)
    succeeded, existingPrefix, exactMatch = trie\tryAdd('acdz')
    assert.that(succeeded)
    assert.that(not trie\tryRemove('a'))
    assert.that(not trie\tryRemove('ac'))
    assert.that(not trie\tryRemove('acd'))
    assertSameContents(trie\getAllEntries(), {'ab', 'acdef', 'acdz'})
    trie\tryRemove('acdef')
    assertSameContents(trie\getAllEntries(), {'ab', 'acdz'})


