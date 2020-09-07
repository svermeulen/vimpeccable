
class assert
  that: (condition, message) ->
    if not condition
      if message
        error("Assert hit! #{message}")
      else
        assert.throw!

  isClassInstance: (instance, classTable) ->
    assert.isEqual(instance.__class, classTable)

  throw: ->
    error("Assert hit!")

  throws: (errorPattern, action) ->
    ok, errorStr = pcall(action)
    assert.that(not ok, 'Expected exception but instead nothing was thrown')
    assert.that(errorStr\find(errorPattern) != nil, "Unexpected error message!  Expected '#{errorPattern}' but found '#{errorStr}'")

  isEqual: (left, right) ->
    assert.that(left == right, "Expected '#{left}' to be equal to '#{right}'")

  isNotEqual: (left, right) ->
    assert.that(left != right, "Expected '#{left}' to not be equal to '#{right}'")

