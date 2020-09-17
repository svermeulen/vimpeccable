
class assert
  that: (condition, message) ->
    if not condition
      if message
        error("Assert hit! #{message}")
      else
        assert.throw!

  is_class_instance: (instance, class_table) ->
    assert.is_equal(instance.__class, class_table)

  throw: ->
    error("Assert hit!")

  throws: (error_pattern, action) ->
    ok, error_str = pcall(action)
    assert.that(not ok, 'Expected exception but instead nothing was thrown')
    assert.that(error_str\find(error_pattern) != nil, "Unexpected error message!  Expected '#{error_pattern}' but found:\n#{error_str}")

  is_equal: (left, right) ->
    assert.that(left == right, "Expected '#{left}' to be equal to '#{right}'")

  is_not_equal: (left, right) ->
    assert.that(left != right, "Expected '#{left}' to not be equal to '#{right}'")

