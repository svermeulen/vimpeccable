
assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")
UniqueTrie = require("vimp.unique_trie")

class Tester

  test_adds: =>
    trie = UniqueTrie()

    succeeded, existing_prefix, exact_match = trie\try_add('abc')
    assert.that(succeeded)
    assert.that(existing_prefix == nil)
    assert.that(not exact_match)

    succeeded, existing_prefix, exact_match = trie\try_add('abc')
    assert.that(not succeeded)
    assert.that(existing_prefix == 'abc')
    assert.that(exact_match)

    succeeded, existing_prefix, exact_match = trie\try_add('abcd')
    assert.that(not succeeded)
    assert.that(existing_prefix == 'abc')
    assert.that(not exact_match)

    -- We can share prefixes with other entries, but each prefix
    -- must not be an entire other entry
    succeeded, existing_prefix, exact_match = trie\try_add('abxyz')
    assert.that(succeeded)
    assert.that(existing_prefix == nil)
    assert.that(not exact_match)

    succeeded, existing_prefix, exact_match = trie\try_add('a')
    assert.that(not succeeded)
    assert.that(existing_prefix == 'a')
    assert.that(not exact_match)

    -- Note that they are the full matches here
    helpers.assert_same_contents(trie\get_all_entries(), {'abc', 'abxyz'})
    helpers.assert_same_contents(trie\get_all_suffixes(''), {'abc', 'abxyz'})
    helpers.assert_same_contents(trie\get_all_suffixes('a'), {'bc', 'bxyz'})
    helpers.assert_same_contents(trie\get_all_suffixes('ab'), {'c', 'xyz'})
    helpers.assert_same_contents(trie\get_all_suffixes('abc'), {})

  test_remove: =>
    trie = UniqueTrie()
    succeeded, existing_prefix, exact_match = trie\try_add('ab')
    assert.that(succeeded)
    helpers.assert_same_contents(trie\get_all_entries(), {'ab'})
    assert.that(not trie\try_remove('a'))
    assert.that(trie\try_remove('ab'))
    helpers.assert_same_contents(trie\get_all_entries(), {})
    succeeded, existing_prefix, exact_match = trie\try_add('ab')
    assert.that(succeeded)
    succeeded, existing_prefix, exact_match = trie\try_add('acdef')
    assert.that(succeeded)
    succeeded, existing_prefix, exact_match = trie\try_add('acdz')
    assert.that(succeeded)
    assert.that(not trie\try_remove('a'))
    assert.that(not trie\try_remove('ac'))
    assert.that(not trie\try_remove('acd'))
    helpers.assert_same_contents(trie\get_all_entries(), {'ab', 'acdef', 'acdz'})
    trie\try_remove('acdef')
    helpers.assert_same_contents(trie\get_all_entries(), {'ab', 'acdz'})


