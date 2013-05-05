-- WolfOS File Handler (SERVER)

WDM = os.getApiSided "WDM"

export isDir = (absPath) ->
    ok, err = ftype "string", absPath
    if not ok
        error err, 2
    
    return fs.isDir absPath

export list = (absPath, sort) ->
    ok, err = ftype "string", absPath
    if not ok
        error err, 2
    
    all = fs.list absPath
    dirs, files = {}, {}
    
    for n, item in pairs all
        if fs.isDir fs.combine absPath, item
            table.insert dirs, item
        else
            table.insert files, item
    
    if sort == "files"
        return files
    elseif sort == "dirs"
        return dirs
    else
        return all

export move = (absPath, destPath) ->
    ok, err = ftype "string, string", absPath, destPath
    if not ok
        error err, 2
    
    fs.move absPath, destPath

export copy = (absPath, destPath) ->
    ok, err = ftype "string, string", absPath, destPath
    if not ok
        error err, 2
    
    fs.copy absPath, destPath

export delete = (absPath) ->
    ok, err = ftype "string", absPath
    if not ok
        error err, 2
    
    fs.delete absPath
