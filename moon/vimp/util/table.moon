
class Table
  clear: (table) ->
    for key in pairs (table)
        table[key] = nil

  getKeys: (table) ->
    [k for k, _ in pairs(table)]

  shallowCopy: (t) ->
    t2 = {}
    for k,v in pairs(t) do
      t2[k] = v
    return t2

