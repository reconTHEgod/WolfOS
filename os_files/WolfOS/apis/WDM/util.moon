-- WolfOS Data Management Library
-- Util Module

export matchFromTable = (table, string, startPos = 1, partial = false) ->
    for n = startPos, #table
        start, _end = string.find table[n], string
        if (start == 1 and _end == #table[n]) or (start and partial == true)
            return n
