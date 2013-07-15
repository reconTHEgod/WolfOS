-- WolfOS Data Management Library

-- File management package

export exists = (path) ->
    file = fs.open path, "r"
    if file
        file.close!
        return true

export readToTable = (path) ->
    if exists path
        file = fs.open path, "r"
        lines = {}
        line = ""
            
        while line
            line = file.read!
            table.insert lines, line
            
        file.close!
        return lines

export readLine = (path, line) ->
    if exists path
        lines = readToTable path
        return lines[line]
    
export readAll = (path) ->
    if exists path
        file = fs.open path, "r"
        text = file.readAll!
        file.close!
        return text
    
export write = (path, text = "") ->
    file = fs.open path, "w"
    file.write text
    file.close!
    
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
    file = fs.open path, "a"
    file.write text.."\n"
    file.close!
    
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

-- Data handler package

TextUtils = require "rom.apis.TextUtils"
Crypt = os.getApi "Crypt"

dataTemp = {}
dataClient = nil
dataServer = nil

export readData = (path) ->
    return TextUtils.unserialize Crypt.fromBase64 readAll path

export writeData = (path, table) ->
    write path, Crypt.toBase64 TextUtils.serialize table

export readTempData = (k) ->
    if k
        return dataTemp[k]
    return dataTemp

export readClientData = (k) ->
    if not dataClient
        dataClient = readData os.getSystemDir("data").."client.dat"
    if k
        return dataClient[k]
    return dataClient

export readServerData = (k) ->
    if not dataServer
        dataServer = readData os.getSystemDir("data").."server.dat"
    if k
        return dataServer[k]
    return dataServer

export writeTempData = (v, k) ->
    if k
        dataTemp[k] = v
    elseif type(v) == "table"
        dataTemp = v

export writeClientData = (v, k) ->
    if not dataClient
        dataClient = readData os.getSystemDir("data").."client.dat"
    if k
        dataClient[k] = v
    elseif type(v) == "table"
        dataClient = v
    writeData os.getSystemDir("data").."client.dat", dataClient

export writeServerData = (v, k) ->
    if not dataServer
        dataServer = readData os.getSystemDir("data").."server.dat"
    if k
        dataServer[k] = v
    elseif type(v) == "table"
        dataServer = v
    writeData os.getSystemDir("data").."server.dat", dataServer

-- Utils package

export matchFromTable = (table, string, startPos = 1, partial = false) ->
    for n = startPos, #table
        start, _end = string.find table[n], string
        if (start == 1 and _end == #table[n]) or (start and partial == true)
            return n

export list = (dir) ->
    all = fs.list dir
    dirs, files = {}, {}
    
    for n, item in pairs all
        if fs.isDir fs.combine dir, item
            table.insert dirs, item
        else
            table.insert files, item
    
    return dirs, files
