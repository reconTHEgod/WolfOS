-- WolfOS File Handler

Data = os.getApi "Data"
Network = os.getApi "Network"

getSide = -> return Data.readTempData "current_side"
getModemPort = -> return Data.readServerData "modem_port"
getRelayAddress = -> return Data.readTempData "parent_address"
getServerState = -> return Data.readServerData "server_state"
getServerModuleChannel = ->
    modules = Data.readTempData("server_modules") or {}
    if modules.file
        return modules.file.channel

getServerAddress = ->
    channel = getServerModuleChannel!
    address =  Data.readServerData "server_address"
    
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
    
    switch getSide!
        when "Side.CLIENT"
            Network.send getModemPort!, getRelayAddress!, thisAddress!, getServerAddress!, {"is_dir", absPath}
            data = Network.listen getModemPort!, getServerModuleChannel!, 5
            
            if data and data[1] == "is_dir_response"
                return data[2]
        when "Side.SERVER"
            return fs.isDir absPath
    
    return false

export list = (absPath, sort) ->
    ok, err = ftype "string", absPath
    if not ok
        error err, 2
    
    switch getSide!
        when "Side.CLIENT"
            Network.send getModemPort!, getRelayAddress!, thisAddress!, getServerAddress!, {"list_contents", absPath, sort}
            data = Network.listen getModemPort!, getServerModuleChannel!, 5
            
            if data and data[1] == "list_contents_response"
                return data[2]
        when "Side.SERVER"
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
    
    switch getSide!
        when "Side.CLIENT"
            Network.send getModemPort!, getRelayAddress!, thisAddress!, getServerAddress!, {"move_item", absPath, destPath}
        when "Side.SERVER"
            fs.move absPath, destPath

export copy = (absPath, destPath) ->
    ok, err = ftype "string, string", absPath, destPath
    if not ok
        error err, 2
    
    switch getSide!
        when "Side.CLIENT"
            Network.send getModemPort!, getRelayAddress!, thisAddress!, getServerAddress!, {"copy_item", absPath, destPath}
        when "Side.SERVER"
            fs.copy absPath, destPath

export delete = (absPath) ->
    ok, err = ftype "string", absPath
    if not ok
        error err, 2
    
    switch getSide!
        when "Side.CLIENT"
            Network.send getModemPort!, getRelayAddress!, thisAddress!, getServerAddress!, {"delete_item", absPath}
        when "Side.SERVER"
            fs.delete absPath
