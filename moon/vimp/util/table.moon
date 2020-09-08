
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

  indexOf: (list, item) ->
    for i = 1,#list
      if item == list[i]
        return i

    return -1

  contains: (list, item) ->
    return Table.indexOf(list, item) != -1

