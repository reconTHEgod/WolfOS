-- WolfOS File Handler (CLIENT)

WDM = os.getApiSided "WDM"
WNC = os.getApiSided "WNC"

getModemPort = -> return WDM.readServerData "modem_port"
getRelayAddress = -> return WDM.readTempData "parent_address"
getServerState = -> return WDM.readServerData "server_state"
getServerModuleChannel = ->
    modules = WDM.readTempData("server_modules") or {}
    if modules.file
        return modules.file.channel

getServerAddress = ->
    channel = getServerModuleChannel!
    address =  WDM.readServerData "server_address"
    
    if address and channel
        return string.match(address, "(%d+):(%d+)")..":"..channel

thisAddress = ->
    channel = getServerModuleChannel!
    if channel
        return os.getComputerID!..":"..channel

export isDir = (absPath) ->
    ok, err = ftype "string", absPath
    if not ok
        error err, 2
    
    WNC.send getModemPort!, getRelayAddress!, thisAddress!, getServerAddress!, {"is_dir", absPath}
    data = WNC.listen getModemPort!, getServerModuleChannel!, 5
        
    if data and data[1] == "is_dir_response"
        return data[2]
    else
        return false

export list = (absPath, sort) ->
    ok, err = ftype "string", absPath
    if not ok
        error err, 2
    
    WNC.send getModemPort!, getRelayAddress!, thisAddress!, getServerAddress!, {"list_contents", absPath, sort}
    data = WNC.listen getModemPort!, getServerModuleChannel!, 5
    
    if data and data[1] == "list_contents_response"
        return data[2]
    else
        return false

export move = (absPath, destPath) ->
    ok, err = ftype "string, string", absPath, destPath
    if not ok
        error err, 2
    
    WNC.send getModemPort!, getRelayAddress!, thisAddress!, getServerAddress!, {"move_item", absPath, destPath}

export copy = (absPath, destPath) ->
    ok, err = ftype "string, string", absPath, destPath
    if not ok
        error err, 2
    
    WNC.send getModemPort!, getRelayAddress!, thisAddress!, getServerAddress!, {"copy_item", absPath, destPath}

export delete = (absPath) ->
    ok, err = ftype "string", absPath
    if not ok
        error err, 2
    
    WNC.send getModemPort!, getRelayAddress!, thisAddress!, getServerAddress!, {"delete_item", absPath}
