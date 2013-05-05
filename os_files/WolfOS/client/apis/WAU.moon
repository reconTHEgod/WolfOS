-- WolfOS Account Utilities (CLIENT)

WDM = os.getApiSided "WDM"
WNC = os.getApiSided "WNC"

getModemPort = -> return WDM.readServerData "modem_port"
getRelayAddress = -> return WDM.readTempData "parent_address"
getServerState = -> return WDM.readServerData "server_state"
getServerModuleChannel = ->
    modules = WDM.readTempData("server_modules") or {}
    if modules.user
        return modules.user.channel

getServerAddress = ->
    channel = getServerModuleChannel!
    address =  WDM.readServerData "server_address"
    
    if address and channel
        return string.match(address, "(%d+):(%d+)")..":"..channel

thisAddress = ->
    channel = getServerModuleChannel!
    if channel
        return os.getComputerID!..":"..channel

users = {}

generateUID = ->
    uid = ""
    chars = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l"
        "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"}
    
    math.randomseed(os.getComputerID! + os.clock!)
    for char = 1, 8
        if math.random(0, 1) == 0
            uid ..= chars[math.random 1, 10]
        else
            uid ..= chars[math.random 11, 36]
    return uid

export getUsers = ->
    WNC.send getModemPort!, getRelayAddress!, thisAddress!, getServerAddress!, {"data_request", "user_list"}
    data = WNC.listen getModemPort!, getServerModuleChannel!, 5
    
    if data and data[1] == "request_success"
        users = data[2]
        
    return users

export exists = (user) ->
    ok, err = ftype "string", user
    if not ok
        error err, 2
    
    users = getUsers!
    
    if ftype "table", users
        for k, v in ipairs users
            if user == v.uid or user == v.name
                return v, k

export createUser = (name, hash, type = "user") ->
    ok, err = ftype "string, string, string", name, hash, type
    if not ok
        error err, 2
    
    WNC.send getModemPort!, getRelayAddress!, thisAddress!, getServerAddress!, {"data_update", "new_user", name, hash, type}

export removeUser = (_user) ->
    ok, err = ftype "string", _user
    if not ok
        error err, 2
    
    WNC.send getModemPort!, getRelayAddress!, thisAddress!, getServerAddress!, {"data_update", "remove_user", _user}

export changeUserData = (_user, k, v) ->
    ok, err = ftype "string, string, string", _user, k, v
    if not ok
        error err, 2
    
    WNC.send getModemPort!, getRelayAddress!, thisAddress!, getServerAddress!, {"data_update", "update_user", _user, k, v}

export checkLogin = (name, hash) ->
    if ftype "string, string", name, hash
        WNC.send getModemPort!, getRelayAddress!, thisAddress!, getServerAddress!, {"login_attempt", name, hash}
        data = WNC.listen getModemPort!, getServerModuleChannel!, 5
        
        if data and data[1] == "login_success"
            WDM.writeTempData false, "local_user"
            return true, data[2]
    
    return false, "Invalid username or password!"
