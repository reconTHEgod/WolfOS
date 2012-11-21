-- WolfOS Data Management Library

export exists = (path) ->
    file = io.open path, "r"
    if file
        file\close!
        return true

export readToTable = (path) ->
    if exists path
        file = io.open path, "r"
        lines = {}
        line = ""
            
        while line
            line = file\read!
            table.insert lines, line
            
        file\close!
        return lines

export readLine = (path, line) ->
    if exists path
        lines = readToTable path
        return lines[line]
    
export readAll = (path) ->
    if exists path
        file = io.open path, "r"
        text = file\read "*a"
        file\close!
        return text
    
export write = (path, text = "") ->
    file = io.open path, "w"
    file\write text
    file\close!
    
export writeFromTable = (path, lines) ->
    text = ""
    for n = 1, #lines
        text ..= lines[n].."\n"
    write path, text
    
export prepend = (path, text) ->
    _text = readAll path
    write path, text.."\n".._text
    
export prependFromTable = (path, lines) ->
    text = ""
    for n = 1, #lines
        text ..= lines[n].."\n"
    prepend path, text
    
export append = (path, text) ->
    file = io.open path, "a"
    file\write text.."\n"
    file\close!
    
export appendFromTable = (path, lines) ->
    text = ""
    for n = 1, #lines
        text ..= lines[n].."\n"
    append path, text
    
export replaceLine = (path, line, text) ->
    lines = readToTable path
    lines[line] = text
    writeFromTable path, lines
    
export removeLine = (path, line) ->
    lines = readToTable path
    table.remove lines, line
    writeFromTable path, lines
