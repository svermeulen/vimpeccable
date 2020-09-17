
class Table
  clear: (table) ->
    for key in pairs (table)
        table[key] = nil

  get_keys: (table) ->
    [k for k, _ in pairs(table)]

  shallow_copy: (t) ->
    t2 = {}
    for k,v in pairs(t) do
      t2[k] = v
    return t2

  index_of: (list, item) ->
    for i = 1,#list
      if item == list[i]
        return i

    return -1

  contains: (list, item) ->
    return Table.index_of(list, item) != -1

