-- WolfOS Account Utilities

getOnline = -> return WDM.data.readClientData("online")
getServerID = -> return WDM.data.readClientData("server_id")
getServerState = -> return WDM.data.readServerData("server_state")

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
    if getOnline! and getServerID! and not getServerState!
        -- TODO: Send request to Server
        sleep 1
    else
        users = WDM.data.readData os.getSystemDir("data").."users.dat"
        
    return users

export exists = (user) ->
    users = getUsers!
    
    if type(users) == "table"
        for k, v in ipairs users
            if user == v.uid or user == v.name
                return v, k

export createUser = (name, hash, type = "user") ->
    --if getOnline! and getServerID! and not getServerState!
        -- TODO: Send request to Server
    --else
    uid = generateUID!
    user = {uid: uid, name: name, hash: hash, type: type}
    table.insert users, user
    WDM.data.writeData os.getSystemDir("data").."users.dat", users
    fs.makeDir os.getSystemDir("users")..uid.."/"

export removeUser = (_user) ->
    --if getOnline! and getServerID! and not getServerState!
        -- TODO: Send request to Server
    --else
    user, i = exists _user
    if user
        table.remove users, i
        WDM.data.writeData os.getSystemDir("data").."users.dat", users
        
        dir = os.getSystemDir("users")..user.uid.."/"
        if fs.exists dir
            fs.delete dir

export changeUserData = (_user, k, v) ->
    --if getOnline! and getServerID! and not getServerState!
        -- TODO: Send request to Server
    --else
    user, i = exists _user
    if user
        if k != "uid"
            user[k] = v
            users[i] = user
    WDM.data.writeData os.getSystemDir("data").."users.dat", users

export checkLogin = (name, _hash) ->
    --if getOnline! and getServerID! and not getServerState!
        -- TODO: Send request to Server
    --else
    user = exists name
    if user
        if name == user.name and _hash == user.hash
            WDM.data.writeTempData true, "local_user"
            return true, user
    return false, "Invalid username or password!"
