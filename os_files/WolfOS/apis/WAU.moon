-- WolfOS Account Utilities

WDM = require os.getSystemDir("apis").."WDM..lua"

getServerChannel = -> return WDM.readClientData("server_channel")
getServerState = -> return WDM.readServerData("server_state")

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
    if getServerChannel! and not getServerState!
        -- TODO: Send request to Server
        sleep 1
    else
        users = WDM.readData os.getSystemDir("data").."users.dat"
        
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
    
    if getServerChannel! and not getServerState!
        -- TODO: Send request to Server
        sleep 1
    else
        uid = generateUID!
        table.insert users, {uid: uid, name: name, hash: hash, type: type}
        WDM.writeData os.getSystemDir("data").."users.dat", users
        fs.makeDir os.getSystemDir("users")..uid.."/"

export removeUser = (_user) ->
    ok, err = ftype "string", _user
    if not ok
        error err, 2
    
    if getServerChannel! and not getServerState!
        -- TODO: Send request to Server
        sleep 1
    else
        user, i = exists _user
        if user
            table.remove users, i
            WDM.writeData os.getSystemDir("data").."users.dat", users
            
            dir = os.getSystemDir("users")..user.uid.."/"
            if fs.exists dir
                fs.delete dir

export changeUserData = (_user, k, v) ->
    ok, err = ftype "string, string, string", _user, k, v
    if not ok
        error err, 2
    
    if getServerChannel! and not getServerState!
        -- TODO: Send request to Server
        sleep 1
    else
        user, i = exists _user
        if user
            if k != "uid"
                user[k] = v
                users[i] = user
                WDM.writeData os.getSystemDir("data").."users.dat", users

export checkLogin = (name, _hash) ->
    ok, err = ftype "string, string", name, _hash
    if not ok
        error err, 2
    
    if getServerChannel! and not getServerState!
        -- TODO: Send request to Server
        sleep 1
    else
        user = exists name
        if user
            if name == user.name and _hash == user.hash
                WDM.writeTempData true, "local_user"
                return true, user
        return false, "Invalid username or password!"
