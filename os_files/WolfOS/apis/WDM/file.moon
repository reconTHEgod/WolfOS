-- WolfOS Data Management Library
-- File Module

file = {
    exists: (path) ->
        _file = io.open path, "r"
        if _file
            _file\close!
            return true

    readToTable: (path) ->
        if exists path
            _file = io.open path, "r"
            lines = {}
            line = ""
            
            while line
                line = _file\read!
                table.insert lines, line
            
            _file\close!
            return lines

    readLine: (path, line) ->
        if exists path
            lines = readToTable path
            return lines[line]
    
    readAll: (path) ->
        if exists path
            _file = io.open path, "r"
            text = _file\read "*a"
            _file\close!
            return text
    
    write: (path, text = "") ->
        _file = io.open path, "w"
        _file\write text
        _file\close!
    
    writeFromTable: (path, lines) ->
        text = ""
        for n = 1, #lines
            text ..= lines[n].."\n"
        write path, text
    
    prepend: (path, text) ->
        _text = readAll path
        write path, text.."\n".._text
    
    prependFromTable: (path, lines) ->
        text = ""
        for n = 1, #lines
            text ..= lines[n].."\n"
        append path, text
    
    append: (path, text) ->
        _file = io.open path, "a"
        _file\write text.."\n"
        _file\close!
    
    appendFromTable: (path, lines) ->
        text = ""
        for n = 1, #lines
            text ..= lines[n].."\n"
        append path, text
    
    replaceLine: (path, line, text) ->
        lines = readToTable path
        lines[line] = text
        writeFromTable path, lines
    
    removeLine: (path, line) ->
        lines = readToTable path
        table.remove lines, line
        writeFromTable path, lines
}
setmetatable file, {__index: getfenv!}
