-- WolfOS Shell

term = require "rom.apis.term"
import clear, print, printError, read, write from debug

ok, err = pcall ->
    if not os.getComputerLabel!
        os.setComputerLabel "ID #"..os.getComputerID!
    
    logAndDisplay = (message, level) ->
        t = log message, level
        print "["..t.level.."]["..t.thread.."] "..t.message
    
    logAndDisplay "Initializing WolfOS "..os.getVersion!
    
    WDM = os.getApi "WDM"
    WNC = os.getApi "WNC"
    WUI = os.getApi "WUI"
    
    crypt = require os.getSystemDir("apis").."crypt"
    peripheral = require "rom.apis.peripheral"
    textutils = require "rom.apis.textutils"
    
    logAndDisplay "Checking integrity of System files"
    
    _dirs = os.getSystemDir!
    _dirs.apis, _dirs.server, _dirs.lang, _dirs.controlPanel = nil, nil, nil, nil
    for k, v in ipairs _dirs
        if not fs.isDir v
            fs.makeDir v
    
    if not WDM.exists os.getSystemDir("data").."client.dat"
        WDM.write os.getSystemDir("data").."client.dat", crypt.toBase64 textutils.serialize {}
    if not WDM.exists os.getSystemDir("data").."server.dat"
        WDM.write os.getSystemDir("data").."server.dat", crypt.toBase64 textutils.serialize {}
    if not WDM.exists os.getSystemDir("data").."users.dat"
        WDM.write os.getSystemDir("data").."users.dat", crypt.toBase64 textutils.serialize {}
    
    logAndDisplay "Loading Language Localisation"
    currentLocale = WDM.readClientData "current_locale"
    if not currentLocale
        currentLocale = "en_UK"
        WDM.writeClientData currentLocale, "current_locale"
    
    localisation = {}
    
    -- Load Locale files from HDD
    searchPath = os.getSystemDir "lang"
    for i, path in ipairs fs.list searchPath
        if not fs.isDir(path) and string.find(path, ".xml")
            name, locale = os.getLocalisationFromFile searchPath..path
            localisation[name] = locale
            logAndDisplay "Locale loaded: "..name
    
    -- Load Locale files from ROM
    searchPath = fs.combine("rom", searchPath).."/"
    for i, path in ipairs fs.list searchPath
        if not fs.isDir(path) and string.find(path, ".xml")
            name, locale = os.getLocalisationFromFile searchPath..path
            localisation[name] = locale
            logAndDisplay "Locale loaded: "..name
    
    WDM.writeTempData localisation, "localisation"
    
    modemPort = WDM.readServerData("modem_port") or ""
    if not peripheral.getType(modemPort) == "modem"
        modemPort = nil
        WDM.writeServerData "", "modem_port"
    
    modules = {}
    WDM.writeTempData "Side.SERVER", "current_side"
    
    if modemPort
        logAndDisplay "Attempting to connect to network"
        sleep 0.01
        
        channel = WDM.readServerData "network_channel"
        if not channel
            channel = 7000
            WDM.writeServerData 7000, "network_channel"
        
        thisAddress = os.getComputerID!..":"..channel
        
        WNC.broadcast modemPort, channel, {"HYPERPAW_parent_request"}
        
        data = {}
        while data.receiverAddress != thisAddress
            data, err = WNC.listen modemPort, channel, 5
            if not data and err == "timeout"
                break
        
        if data and data[1] == "HYPERPAW_parent_proposal"
            WDM.writeTempData data.senderAddress, "parent_address"
            WNC.send modemPort, data.senderAddress, thisAddress, data.senderAddress, {"HYPERPAW_child_registry"}
            
            logAndDisplay "Connection established"
        else
            logAndDisplay "Connection timed out", "warning"
        
        if WDM.readServerData "server_state"
            logAndDisplay "Loading Server modules"
            
            modules.core = {
                channel: channel
                thread: ->
                    modemPort = WDM.readServerData "modem_port"
                    channel = WDM.readServerData "network_channel"
                    thisAddress = os.getComputerID!..":"..channel
                    
                    while true
                        data = WNC.listen(modemPort, channel) or {}
                        
                        switch data[1]
                            when "test_connection"
                                WNC.send modemPort, data.senderAddress, thisAddress, data.sourceAddress, {"connection_response"}
                            when "connection_request"
                                -- TODO: Check whitelist here
                                if true
                                    _modules = WDM.readTempData "server_modules"
                                    
                                    for k, v in pairs _modules
                                        _modules[k].thread = nil
                                    
                                    WNC.send modemPort, data.senderAddress, thisAddress, data.sourceAddress, {"connection_success", _modules}
                                else
                                    WNC.send modemPort, data.senderAddress, thisAddress, data.sourceAddress, {"connection_failure", "not_whitelisted"}
            }
            
            logAndDisplay "Server module loaded: CORE"
            
            -- Load Server Modules from HDD
            searchPath = os.getSystemDir "server"
            for i, path in ipairs fs.list searchPath
                if not fs.isDir(path) and string.find(path, ".lua")
                    name, module = os.getModuleFromFile searchPath..path
                    modules[name] = module
                    logAndDisplay "Server module loaded: "..string.upper name
            
            -- Load Server Modules from ROM
            searchPath = fs.combine("rom", os.getSystemDir("server")).."/"
            for i, path in ipairs fs.list searchPath
                if not fs.isDir(path) and string.find(path, ".lua")
                    name, module = os.getModuleFromFile searchPath..path
                    modules[name] = module
                    logAndDisplay "Server module loaded: "..string.upper name
            
            WDM.writeTempData modules, "server_modules"
        elseif WDM.readTempData("parent_address") and WDM.readServerData("server_address")
            logAndDisplay "Attempting to connect to server"
            
            serverAddress = WDM.readServerData "server_address"
            receiverAddress = WDM.readTempData "parent_address"
            sourceAddress = os.getComputerID!..":"..channel
            
            WNC.send modemPort, receiverAddress, sourceAddress, serverAddress, {"connection_request"}
            data, err = WNC.listen modemPort, channel, 5
            
            if data and data[1] == "connection_success"
                WDM.writeTempData data[2], "server_modules"
                WDM.writeTempData "Side.CLIENT", "current_side"
                WDM.writeServerData data.sourceAddress, "server_address"
                
                logAndDisplay "Connection established"
            elseif not data and err == "timeout"
                logAndDisplay "Connection timed out", "warning"
    
    logAndDisplay "Loading Themes"
    theme = WDM.readClientData "current_theme"
    if not theme
        theme = "Default"
        WDM.writeClientData theme, "current_theme"
    
    themes = {}
    
    -- Load Theme files from ROM
    searchPath = fs.combine("rom", os.getSystemDir("themes")).."/"
    for i, path in ipairs fs.list searchPath
        if fs.isDir searchPath..path
            name, theme = os.getThemeFromFile searchPath..path
            themes[name] = theme
            logAndDisplay "Theme loaded: "..name
    
    -- Load Theme files from HDD
    searchPath = os.getSystemDir "themes"
    for i, path in ipairs fs.list searchPath
        if fs.isDir searchPath..path
            name, theme = os.getThemeFromFile searchPath..path
            themes[name] = theme
            logAndDisplay "Theme loaded: "..name
    
    WDM.writeTempData themes, "themes"
    
    logAndDisplay "Loading User Interface"
    if WUI.getScreenWidth! < 51 or WUI.getScreenHeight! < 19
        log WUI.getLocalisedString("error.shell.screen_dims"), "severe"
        error ""
    if not term.isColour!
        log WUI.getLocalisedString("error.shell.screen_colour"), "severe"
        error ""
    
    _SYSTEM_THREAD = ->
        if fs.exists "rom/"..os.getSystemDir("client").."startup.lua"
            os.run {}, "rom/"..os.getSystemDir("client").."startup.lua"
        elseif fs.exists os.getSystemDir("client").."startup.lua"
            os.run {}, os.getSystemDir("client").."startup.lua"
        else
            error "No startup.lua file found!"
    
    os.addProcess "SYSTEM_THREAD", _SYSTEM_THREAD
    
    for k, v in pairs modules
        os.addProcess string.upper(k).."_NETWORK_THREAD", v.thread
    
    ok, err, process = os.startProcesses!
    if not ok
        log err, "severe", process
        error ""

-- Display error if OS errored
term.setBackgroundColour 32768 -- Black
term.setTextColour 1 -- White
clear!
if not ok
    log err, "severe"
    printError "WolfOS has encountered an issue."
    
    dumpLocation = os.getSystemDir("root").."error_dump.log"
    file = fs.open dumpLocation, "w"
    
    if file
        for k, v in ipairs getLogBuffer!
            file.writeLine "["..v.level.."]["..v.thread.."] "..v.message
        
        file.close!
        print "The error log has been dumped to: "..dumpLocation.."\n"

-- Command line colours
backgroundColour = 32768 -- Black
userText = 1 -- White
promptText = if term.isColour! then 32 else 1 -- Lime else White
text = if term.isColour! then 16 else 1 -- Yellow else White

-- Drop to command line
term.setTextColour text
print "Dropping to WolfOS command line.\nType 'help' to view a list of available commands.\n"

running = true
commandHistory = {}
currentUser = nil
currentPath = ""
    
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
    log: ->
        buffer = getLogBuffer!
        t = {}
        
        for k, v in ipairs buffer
            table.insert t, "["..v.level.."]["..v.thread.."] "..v.message
        
        list t, false
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
    WDM = os.getApi "WDM"
    WFH = os.getApi "WFH"
    
    resolve = (path) ->
        startChar = path\sub 1, 1
        
        if startChar == "/"
            return fs.combine "", path
        else
            return fs.combine currentPath, path
    
    commands.cd = (path) ->
        if ftype "string", path
            newPath = resolve path
            
            if WFH.isDir newPath
                currentPath = newPath
            else
                printError "Invalid path"
        else
            printError "Usage: cd <path>"
    commands.list = (path = currentPath) ->
        dirs = WFH.list path, "dirs"
        files = WFH.list path, "files"
        
        if term.isColour! then term.setTextColour 512 -- Cyan
        list dirs
        
        term.setTextColour text
        list files
    commands.delete = (path) ->
        if ftype "string", path
            newPath = resolve path
            WFH.delete newPath
        else
            printError "Usage: delete <path>"
    commands.copy = (srcPath, destPath) ->
        if ftype "string, string", srcPath, destPath
            srcPath = resolve srcPath
            destPath = resolve destPath
            
            if fs.exists(destPath) and fs.isDir(destPath)
                destPath = fs.combine destPath, fs.getName srcPath
            
            WFH.copy srcPath, destPath
        else
            printError "Usage: copy <source> <destination>"
    commands.move = (srcPath, destPath) ->
        if ftype "string, string", srcPath, destPath
            srcPath = resolve srcPath
            destPath = resolve destPath
            
            if fs.exists(destPath) and fs.isDir(destPath)
                destPath = fs.combine destPath, fs.getName srcPath
            
            WFH.move srcPath, destPath
        else
            printError "Usage: move <source> <destination>"
    commands.rename = (srcPath, destPath) ->
        if ftype "string, string", srcPath, destPath
            commands.move srcPath, destPath
        else
            printError "Usage: rename <source> <destination>"
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
                if ftype "string, string, string", type, key, value
                    if value == "true"
                        value = true
                    elseif value == "false"
                        value = false
                    elseif value == "nil"
                        value = nil
                    
                    switch type
                        when "temp"
                            WDM.writeTempData value, key
                        when "client"
                            WDM.writeClientData value, key
                        when "server"
                            WDM.writeServerData value, key
                        else
                            printError "Usage: data write <temp|client|server> <key> <value>"
                else
                    printError "Usage: data write <temp|client|server> <key> <value>"
            else
                printError "You do not have permission to perform this action!"
    }

-- HyperPaw Network command set
pcall ->
    WDM = os.getApi "WDM"
    WNC = os.getApi "WNC"
    commands.network = {
        connect: (modemPort, channel) ->
            channel = tonumber channel
            ok = ftype("string, +number", modemPort, channel) and WNC.checkModemPort(modemPort)
            
            if ok
                thisAddress = os.getComputerID!..":"..channel
                
                WNC.broadcast modemPort, channel, {"HYPERPAW_parent_request"}
                
                data = {}
                while data.receiverAddress != thisAddress
                    data, err = WNC.listen modemPort, channel, 5
                    if not data and err == "timeout"
                        break
                
                if data and data[1] == "HYPERPAW_parent_proposal"
                    WDM.writeServerData channel, "network_channel"
                    WDM.writeTempData data.senderAddress, "parent_address"
                    WNC.send modemPort, data.senderAddress, thisAddress, data.senderAddress, {"HYPERPAW_child_registry"}
                else
                    printError "Timed out"
            else
                printError "Usage: network connect <modem port> <channel>"
        disconnect: ->
            WDM.writeServerData nil, "network_channel"
            WDM.writeTempData nil, "parent_address"
        send: (modemPort, receiverAddress, destinationAddress, ...) ->
            ok = ftype("string, string, string", modemPort, receiverAddress, destinationAddress) and WNC.checkModemPort(modemPort)
            
            if ok
                channel = receiverAddress\match "(%d+)$"
                sourceAddress = os.getComputerID!..":"..channel
                return WNC.send modemPort, receiverAddress, sourceAddress, destinationAddress, {...}
            else
                printError "Usage: network send <modem port> <receiver> <destination> [...]"
        
        listen: (modemPort, channel, timeout) ->
            channel, timeout = tonumber(channel), tonumber(timeout)
            ok = ftype("string, +number, ?+number", modemPort, channel, timeout) and WNC.checkModemPort(modemPort)
            
            if ok
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

-- Server command set
pcall ->
    WDM = os.getApi "WDM"
    WNC = os.getApi "WNC"
    commands.server = {
        connect: (modemPort, serverAddress) ->
            ok = ftype("string, string", modemPort, serverAddress) and WNC.checkModemPort(modemPort)
            
            if ok
                channel = tonumber serverAddress\match "(%d+)$"
                receiverAddress = WDM.readTempData "parent_address"
                sourceAddress = os.getComputerID!..":"..channel
                
                WNC.send modemPort, receiverAddress, sourceAddress, serverAddress, {"connection_request"}
                data = WNC.listen modemPort, channel, 5
                
                if data and data[1] == "connection_success"
                    WDM.writeTempData "Side.CLIENT", "current_side"
                    WDM.writeTempData data[2], "server_modules"
                    WDM.writeServerData false, "server_state"
                    WDM.writeServerData data.sourceAddress, "server_address"
                    
                    currentUser = nil
                else
                    printError "Timed out"
            else
                WDM.writeServerData nil, "server_address"
                printError "Usage: server connect <modem port> <server>"
        disconnect: ->
            WDM.writeTempData "Side.SERVER", "current_side"
            WDM.writeServerData nil, "server_address"
            WDM.writeServerData true, "server_state"
            currentUser = nil
        modules: ->
            modules = WDM.readTempData "server_modules"
            _modules = {}
            t = {}
            
            for i, name in ipairs fs.list os.getSystemDir "server"
                name = name\gmatch("(%a+)%.lua")!
                if name
                    module = modules[name]
                    channel = if module then module.channel else "-"
                    t[name] = string.upper(name)..": "..channel
            for i, name in ipairs fs.list "rom/"..os.getSystemDir "server"
                name = name\gmatch("(%a+)%.lua")!
                if name
                    module = modules[name]
                    channel = if module then module.channel else "-"
                    t[name] = string.upper(name)..": "..channel
            for k, v in pairs modules
                t[k] = string.upper(k)..": "..(v.channel or "-")
            for k, v in pairs t
                table.insert _modules, v
            
            list _modules
        add: (name, channel) ->
            channel = tonumber channel
            
            if ftype "string, +number", name, channel
                modules = WDM.readServerData("server_modules") or {}
                modules[name] = channel
                
                module = nil
                if fs.exists os.getSystemDir("server")..string.lower(name)..".lua"
                    name, module = os.getModuleFromFile os.getSystemDir("server")..string.lower(name)..".lua"
                elseif fs.exists "rom/"..os.getSystemDir("server")..string.lower(name)..".lua"
                    name, module = os.getModuleFromFile "rom/"..os.getSystemDir("server")..string.lower(name)..".lua"
                
                _modules = WDM.readTempData "server_modules"
                _modules[name] = module
                
                os.addProcess string.upper(name).."_NETWORK_THREAD", module.thread
                
                log "Server module loaded: "..string.upper name
                WDM.writeTempData _modules, "server_modules"
                WDM.writeServerData modules, "server_modules"
            else
                printError "Usage: server add <module name> <channel>"
        remove: (name) ->
            if ftype "string", name
                modules = WDM.readServerData("server_modules") or {}
                modules[name] = nil
                
                _modules = WDM.readTempData "server_modules"
                _modules[name] = nil
                
                os.removeProcess string.upper(name).."_NETWORK_THREAD"
                
                log "Server module unloaded: "..string.upper name
                WDM.writeTempData _modules, "server_modules"
                WDM.writeServerData modules, "server_modules"
            else
                printError "Usage: server remove <module name>"
    }

-- User Account command set
pcall ->
    WAU = os.getApi "WAU"
    hash = require os.getSystemDir("apis").."hash"
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
                    if not WAU.exists name
                        WAU.createUser name, hash.sha256 pass
                    else
                        printError "Username already in use!"
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
    
    if currentPath
        write currentPath
    write "> "
    term.setTextColour userText
        
    s = read nil, commandHistory
    table.insert commandHistory, s
        
    term.setTextColour text
    parseLine s

os.shutdown! -- Just in case.
