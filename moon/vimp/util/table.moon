
class Table
  clear: (table) ->
    for key in pairs (table)
        table[key] = nil

  getKeys: (table) ->
    [k for k, _ in pairs(table)]

