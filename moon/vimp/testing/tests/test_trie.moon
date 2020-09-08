
assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")
UniqueTrie = require("vimp.unique_trie")

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
    helpers.assertSameContents(trie\getAllEntries(), {'abc', 'abxyz'})
    helpers.assertSameContents(trie\getAllSuffixes(''), {'abc', 'abxyz'})
    helpers.assertSameContents(trie\getAllSuffixes('a'), {'bc', 'bxyz'})
    helpers.assertSameContents(trie\getAllSuffixes('ab'), {'c', 'xyz'})
    helpers.assertSameContents(trie\getAllSuffixes('abc'), {})

  testRemove: =>
    trie = UniqueTrie()
    succeeded, existingPrefix, exactMatch = trie\tryAdd('ab')
    assert.that(succeeded)
    helpers.assertSameContents(trie\getAllEntries(), {'ab'})
    assert.that(not trie\tryRemove('a'))
    assert.that(trie\tryRemove('ab'))
    helpers.assertSameContents(trie\getAllEntries(), {})
    succeeded, existingPrefix, exactMatch = trie\tryAdd('ab')
    assert.that(succeeded)
    succeeded, existingPrefix, exactMatch = trie\tryAdd('acdef')
    assert.that(succeeded)
    succeeded, existingPrefix, exactMatch = trie\tryAdd('acdz')
    assert.that(succeeded)
    assert.that(not trie\tryRemove('a'))
    assert.that(not trie\tryRemove('ac'))
    assert.that(not trie\tryRemove('acd'))
    helpers.assertSameContents(trie\getAllEntries(), {'ab', 'acdef', 'acdz'})
    trie\tryRemove('acdef')
    helpers.assertSameContents(trie\getAllEntries(), {'ab', 'acdz'})


