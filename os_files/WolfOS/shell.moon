-- WolfOS Shell

term = require "rom.apis.term"
import clear, print, printError, read, write from debug

ok, err = pcall ->
    if not os.getComputerLabel!
        os.setComputerLabel "ID #"..os.getComputerID!
    
    print "Initialising WolfOS "..os.getVersion!.."...\n"
    sleep 0.01
    
    WDM = require os.getSystemDir("apis").."WDM..lua"
    WNC = require os.getSystemDir("apis").."WNC..lua"
    WUI = require os.getSystemDir("apis").."WUI..lua"
    
    crypt = require os.getSystemDir("apis").."crypt..lua"
    
    peripheral = require "rom.apis.peripheral"
    textutils = require "rom.apis.textutils"
    
    print "\nChecking integrity of System files...\n"
    sleep 0.01
    for k, v in pairs os.getSystemDir!
        if not fs.isDir v
            fs.makeDir v
    
    if not WDM.exists os.getSystemDir("data").."client.dat"
        WDM.write os.getSystemDir("data").."client.dat", crypt.toBase64 textutils.serialize {}
    if not WDM.exists os.getSystemDir("data").."server.dat"
        WDM.write os.getSystemDir("data").."server.dat", crypt.toBase64 textutils.serialize {}
    if not WDM.exists os.getSystemDir("data").."users.dat"
        WDM.write os.getSystemDir("data").."users.dat", crypt.toBase64 textutils.serialize {}
    
    print "Loading Language Localisation...\n"
    sleep 0.01
    loc = WDM.readClientData "current_localisation"
    if not loc
        loc = "en_UK"
        WDM.writeClientData loc, "current_localisation"
    
    WDM.writeTempData WDM.readAll(os.getSystemDir("lang")..loc..".xml"), "localisation"
    
    modemPort = WDM.readServerData("modem_port") or ""
    if not peripheral.getType(modemPort) == "modem"
        WDM.writeServerData "", "modem_port"
        WDM.writeServerData false, "online"
    
    modules = {}
    online = WDM.readServerData "online"
    if online
        print "Loading Server modules..."
        sleep 0.01
        loadModule = (path) ->
            name = fs.getName path
            return ->
                os.run {}, path
        
        for k, module in ipairs fs.list os.getSystemDir "server"
            path = os.getSystemDir("server")..module
            if not fs.isDir(path) and string.find module, ".lua"
                moduleName = module\sub 1, (string.find(module, "%.") or #module + 1) - 1
                modules[moduleName] = loadModule path
                print "Server module loaded: "..string.upper moduleName
        
        print "\nAttempting to connect to network..."
        sleep 0.01
        
        channel = WDM.readServerData("network_channel") or 7000
        thisAddress = os.getComputerID!..":"..channel
        
        WNC.broadcast modemPort, channel, {"HYPERPAW_parent_request"}
        
        data = {}
        while data.receiverAddress != thisAddress
            data = WNC.listen modemPort, channel, 5
        
        if data and data[1] == "HYPERPAW_parent_proposal"
            WDM.writeTempData data.senderAddress, "parent_address"
            WNC.send modemPort, data.senderAddress, thisAddress, data.senderAddress, {"HYPERPAW_child_registry"}
            
            print "Connection established\n"
        else
            print "Connection timed out\n"
    
    print "Loading User Interface...\n"
    sleep 0.01
    if WUI.getScreenWidth! < 51 or WUI.getScreenHeight! < 19
        error WUI.getLocalisedString("error.shell.screen_dims"), 0
    
    if not term.isColour!
        error WUI.getLocalisedString("error.shell.screen_colour"), 0
    
    print "Loading Theme...\n"
    sleep 0.01
    theme = WDM.readClientData "current_theme"
    if not theme
        theme = "default"
        WDM.writeClientData theme, "current_theme"
    
    WDM.writeTempData WDM.readAll(os.getSystemDir("themes")..theme..".xml"), "theme"
    
    _SYSTEM_THREAD = ->
        os.run {}, os.getSystemDir("client").."startup.lua"
    
    _CORE_NETWORK_THREAD = ->
        modemPort = WDM.readServerData "modem_port"
        channel = WDM.readServerData "network_channel"
        relay = WDM.readTempData "parent_address"
        thisAddress = os.getComputerID!..":"..channel
        
        while true
            data = WNC.listen(modemPort, channel) or {}
            
            switch data[1]
                when "test_connection"
                    WNC.send modemPort, relay, thisAddress, data.sourceAddress, {"connection_response"}
    
    os.addProcess "SYSTEM_THREAD", _SYSTEM_THREAD
    os.addProcess "CORE_NETWORK_THREAD", _CORE_NETWORK_THREAD
    
    for k, v in pairs modules
        os.addProcess string.upper(k).."_NETWORK_THREAD", v
    
    ok, err = os.startProcesses!
    if not ok
        error err

-- Display error if OS errored
term.setBackgroundColour 32768 -- Black
term.setTextColour 1 -- White
debug.clear!
if not ok
    if err
        debug.print "An error occured during initialization:"
        debug.printError err
    else
        debug.print "An unknown error occured during initialization."
    debug.print!

-- Command line colours
backgroundColour = 32768 -- Black
userText = 1 -- White
promptText = if term.isColour! then 32 else 1 -- Lime else White
text = if term.isColour! then 16 else 1 -- Yellow else White

-- Drop to command line
term.setTextColour text
debug.print "Dropping to WolfOS command line.\nType 'help' to view a list of available commands.\n"

running = true
commandHistory = {}
currentUser = nil
    
list = (data, sort = true) ->
    if sort
        table.sort data, (a, b) ->
            if not string.find(a, " ") and string.find(b, " ")
                return true
            elseif string.find(a, " ") and not string.find(b, " ")
                return false
            else
                return a < b
    
    for k, v in ipairs data
        print v
        x, y = term.getCursorPos!
        w, h = term.getSize!
        if y == h
            term.write "Press any key to continue..."
            os.pullEvent "key"
            term.clearLine!
            term.setCursorPos 1, y
    
-- Table of commands
commands = {
    exit: -> running = false
    version: -> print "WolfOS "..os.getVersion!
    info: -> print "Copyright 2013 James Chapman (toxic.wolf666@gmail.com)"
    clear: -> clear!
    apis: ->
        apis = {}
        for k, v in pairs getfenv 0
            if type(v) == "table" and k != "_G"
                table.insert apis, k
        list apis
    functions: (api) ->
        if ftype "string", api
            t = getfenv(0)[api]
            if t
                functions = {}
                for k, v in pairs t
                    if type(v) == "function"
                        table.insert functions, k
                list functions
            elseif api
                printError "Unknown api: "..api
        else
            printError "Usage: functions <api>"
    lua: (script) ->
        if currentUser and currentUser.type == "admin"
            luaRunning = true
            commandHistory = {}
            env = {
                exit: ->
                    luaRunning = false
                    debug.clear!
            }
            setmetatable env, {__index: getfenv 0}
            
            term.setTextColour text
            print "Interactive Lua prompt."
            print "Call exit() to exit.\n"
            
            while luaRunning
                term.setTextColour promptText
                write "lua> "
                term.setTextColour userText
                
                s = ""
                if script
                    s = "os.run({}, \""..script.."\")"
                    print s
                    script = nil
                else
                    s = read nil, commandHistory
                
                table.insert commandHistory, s
                term.setTextColour text
                
                forcePrint = 0
                func, e = loadstring s, "lua"
                func2, e2 = loadstring "return "..s, "lua"
                if not func
                    if func2
                        func = func2
                        e = nil
                        forcePrint = 1
                else
                    if func2
                        func = func2
                
                if func
                    setfenv func, env
                    results = {pcall -> return func!}
                    if results[1]
                        n = 1
                        term.setTextColour text
                        term.setBackgroundColour backgroundColour
                        if term.getCursorPos! > 1
                            print!
                        while (results[n + 1] != nil) or (n <= forcePrint)
                            print tostring results[n + 1]
                            n += 1
                    else
                        printError results[2]
                else
                    printError e
            
        else
            printError "You do not have permission to perform this action!"
    debug: (filepath) ->
        if ftype "string", filepath
            clear!
            term.setTextColour text
            print "Debugging '"..fs.getName(filepath).."'.\n"
            i = 0
            lines = WDM.readToTable filepath
            w, h = term.getSize!
            
            redraw = ->
                for n = 3, h
                    line = n - 2
                    
                    term.setCursorPos 1, n
                    term.setBackgroundColour colours.white
                    term.setTextColour colours.blue
                    term.write string.sub tostring(line), 1 , #tostring(line) - 2
                    
                    term.setTextColour colours.white
                    term.setCursorPos 3, n
                    
                    if line == i
                        term.setBackgroundColour colours.red
                    else
                        term.setBackgroundColour colours.black
                    if lines[line]
                        term.write lines[line]
                    else
                        break
            
            step = ->
                for k, v in ipairs lines
                    i = k
                    redraw!
                    func, err = loadstring v, "line #"..i
                    if func
                        ok, err = pcall func
                        if not ok
                            printError "\n"..err
                            break
                    else
                        printError "\n"..err
                        break
                    coroutine.yield!
            
            co = coroutine.create step
            while coroutine.status(co) != "dead"
                os.pullEvent "key"
                coroutine.resume co
        else
            printError "Usage: debug <filepath>"
    shutdown: -> os.shutdown!
    reboot: -> os.reboot!
}
commands.help = ->
    _commands = {}
    for k, v in pairs commands
        if type(v) == "table"
            for _k, _v in pairs v
                if type(_v) == "function"
                    table.insert _commands, k.." ".._k
        elseif type(v) == "function"
            table.insert _commands, k
    list _commands

-- Data Handling command set
pcall ->
    WDM = require os.getSystemDir("apis").."WDM..lua"
    commands.data = {
        read: (type, key) ->
            if ftype "?string, ?string", type, key
                data = {}
                switch type
                    when "temp"
                        data = WDM.readTempData!
                    when "client"
                        data = WDM.readClientData!
                    when "server"
                        data = WDM.readServerData!
                    else
                        for k, v in pairs WDM.readTempData! do data[k] = v
                        for k, v in pairs WDM.readClientData! do data[k] = v
                        for k, v in pairs WDM.readServerData! do data[k] = v
                
                if data[key]
                    print key..": "..tostring data[key]
                else
                    _data = {}
                    for k, v in pairs data
                        table.insert _data, k..": "..tostring v
                    list _data
            else
                printError "Usage: data read [temp|client|server] [key]"
        
        write: (type, key, value) ->
            if currentUser and currentUser.type == "admin"
                if ftype "string, string, ?string", type, key, value
                    if value == "true" then value = true
                    elseif value == "false" then value = false
                    
                    switch type
                        when "temp"
                            WDM.writeTempData value, key
                        when "client"
                            WDM.writeClientData value, key
                        when "server"
                            WDM.writeServerData value, key
                        else
                            printError "Usage: data write <temp|client|server> <key> [value]"
                else
                    printError "Usage: data write <temp|client|server> <key> [value]"
            else
                printError "You do not have permission to perform this action!"
    }

-- HyperPaw Network command set
pcall ->
    WNC = require os.getSystemDir("apis").."WNC..lua"
    commands.network = {
        send: (modemPort, receiverAddress, destinationAddress, ...) ->
            if ftype "string, string, string", modemPort, receiverAddress, destinationAddress
                channel = receiverAddress\match "(%d+)$"
                sourceAddress = os.getComputerID!..":"..channel
                return WNC.send modemPort, receiverAddress, sourceAddress, destinationAddress, {...}
            else
                printError "Usage: network send <modem port> <receiver> <destination> [...]"
        
        listen: (modemPort, channel, timeout) ->
            channel, timeout = tonumber(channel), tonumber(timeout)
            if ftype "string, +number, ?+number", modemPort, channel, timeout
                data = WNC.listen modemPort, channel, timeout
                
                if data
                    display = {
                        "Sender: "..data.senderAddress
                        "Source: "..data.sourceAddress
                        "Distance: "..data.distance
                    }
                    
                    for k, v in ipairs data
                        table.insert display, "Packet "..k..": "..tostring(v)
                        
                    list display, false
                else
                    printError "Timed out"
            else
                printError "Usage: network listen <modem port> <channel> <timeout>"
    }

-- User Account command set
pcall ->
    WAU = require os.getSystemDir("apis").."WAU..lua"
    hash = require os.getSystemDir("apis").."hash..lua"
    commands.users = ->
        t = WAU.getUsers!
        if t
            users = {}
            for k, v in ipairs t
                table.insert users, v.uid..": "..v.name.." ("..v.type..")"
            list users
    commands.login = (name) ->
        if not currentUser
            if ftype "string", name
                debug.write "Password: "
                term.setTextColour userText
                pass = read "*"
                ok, p1 = WAU.checkLogin name, hash.sha256 pass
                if ok
                    currentUser = p1
                else
                    printError "An error occured during login: "..p1
            else
                printError "Usage: login <name>"
        else
            printError "You are already logged in as: "..currentUser.name.." ".."("..currentUser.type..")"
    commands.logout = ->
        if currentUser
            currentUser = nil
        else
            printError "You are not logged in!"
    commands.user = {
        create: (name, pass) ->
            if currentUser and currentUser.type == "admin"
                if ftype "string, string", name, pass
                    WAU.createUser name, hash.sha256 pass
                else
                    printError "Usage: user create <name> <pass>"
            else
                printError "You do not have permission to perform this action!"
        
        delete: (user) ->
            if currentUser and currentUser.type == "admin"
                if ftype "string", user
                    WAU.removeUser user
                    if arg1 == currentUser.name or arg1 == currentUser.uid
                        currentUser = nil
                else
                    printError "Usage: user delete <name|uid>"
            else
                printError "You do not have permission to perform this action!"
        
        edit: (user, field, arg) ->
            if currentUser and currentUser.type == "admin"
                if ftype "string, string, string", user, field, arg
                    switch field
                        when "name"
                            WAU.changeUserData user, field, arg
                            if user == currentUser.name or user == currentUser.uid
                                currentUser = WAU.exists arg
                        when "pass"
                            WAU.changeUserData user, "hash", hash.sha256 arg
                            if user == currentUser.name or user == currentUser.uid
                                currentUser = WAU.exists user
                        when "type"
                            WAU.changeUserData user, field, arg
                            if user == currentUser.name or user == currentUser.uid
                                currentUser = WAU.exists user
                        else
                            printError "Unknown field: "..field
                else
                    printError "Usage: user change <name|uid> <field> <parameter>"
            else
                printError "You do not have permission to perform this action!"
    }

-- Read commands and execute them
run = (...) ->
    args = {...}
    set = table.remove args, 1
    
    if type(commands[set]) == "table"
        command = table.remove args, 1
        
        if type(commands[set][command]) == "function"
            return commands[set][command] unpack args
        else
            printError "Unknown command: "..set.." "..(command or "")
    elseif type(commands[set]) == "function"
        command = set
        return commands[command] unpack args
    elseif set
        printError "Unknown command: "..set
    
parseLine = (_line) ->
    words = {}
    for match in string.gmatch _line, "[^ \t]+"
        table.insert words, match
        
    return run unpack words

while running
    term.setBackgroundColour backgroundColour
    term.setTextColour promptText
    if term.getCursorPos! > 1
        print!
    write "> "
    term.setTextColour userText
        
    s = read nil, commandHistory
    table.insert commandHistory, s
        
    term.setTextColour text
    parseLine s

os.shutdown! -- Just in case.
