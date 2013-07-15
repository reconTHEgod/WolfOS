-- WolfOS Shell

import clear, print, printError, read, write from Debug
Term = require "rom.apis.term"
Colors = require "rom.apis.colors"

ok, err = pcall ->
    if not os.getComputerLabel!
        os.setComputerLabel "ID #"..os.getComputerID!
    
    logAndDisplay = (message, level) ->
        with log message, level
            print "[".. .level.."][".. .thread.."] ".. .message
    
    logAndDisplay "Initializing WolfOS "..os.getVersion!
    
    Data = os.getApi "Data"
    Network = os.getApi "Network"
    Interface = os.getApi "Interface"
    Crypt = os.getApi "Crypt"
    
    Peripheral = require "rom.apis.peripheral"
    TextUtils = require "rom.apis.textutils"
    
    logAndDisplay "Checking integrity of System files"
    
    with dirs = os.getSystemDir!
        .apis, .server, .lang, .controlPanel = nil, nil, nil, nil
        
        for k, v in ipairs dirs
            if not fs.isDir v
                fs.makeDir v
    
    path = os.getSystemDir("data").."client.dat"
    if not Data.exists path
        Data.write path
    path = os.getSystemDir("data").."server.dat"
    if not Data.exists path
        Data.write path
    path = os.getSystemDir("data").."users.dat"
    if not Data.exists path
        Data.write path
    
    logAndDisplay "Loading Language Localization"
    
    currentLocale = Data.readClientData "current_locale"
    if not currentLocale
        currentLocale = "en_US"
        Data.writeClientData currentLocale, "current_locale"
    
    localization = {}
    loadLocaleFiles = (searchPath) ->
        for i, path in ipairs fs.list searchPath
            if not fs.isDir(path) and string.find(path, ".xml")
                name, locale = os.getLocalizationFromFile searchPath..path
                localization[name] = locale
                logAndDisplay "Locale loaded: "..name
    
    -- Load Locale files from HDD
    loadLocaleFiles os.getSystemDir "lang"
    -- Load Locale files from ROM
    loadLocaleFiles fs.combine("rom", os.getSystemDir("lang")).."/"
    
    Data.writeTempData localization, "localization"
    
    modemPort = Data.readServerData("modemPort") or ""
    if Peripheral.getType(modemPort) != "modem"
        log "test"
        Data.writeServerData "", "modem_port"
        modemPort = nil
    
    Data.writeTempData "Side.SERVER", "current_side"
    
    modules = {}
    loadModuleFiles = (searchPath) ->
        for i, path in ipairs fs.list searchPath
            if not fs.isDir(path) and string.find(path, ".lua")
                name, module = os.getModuleFromFile searchPath..path
                modules[name] = module
                logAndDisplay "Server module loaded: "..string.upper name
    
    if modemPort
        logAndDisplay "Attempting to connect to network"
        
        channel = Data.readServerData "network_channel"
        if not channel
            Data.writeServerData 7000, "network_channel"
            channel = 7000
        
        thisAddress = os.getComputerID!..":"..channel
        
        log type(modemPort)
        Network.broadcast modemPort, channel, {"HYPERPAW_parent_request"}
        
        with data = {}
            while .receiverAddress != thisAddress
                data, err = Network.listen modemPort, channel, 5
                
                if not data and err == "timeout"
                    break
            
            if data and data[1] == "HYPERPAW_parent_proposal"
                Data.writeTempData .senderAddress, "parent_address"
                Network.send modemPort, .senderAddress, thisAddress, .senderAddress, {"HYPERPAW_child_registry"}
                
                logAndDisplay "Connection established"
            else
                logAndDisplay "Connection timed out", "warning"
            
            if Data.readServerData "server_state"
                logAndDisplay "Loading Server modules"
                
                modules.core = {
                    channel: channel
                    thread: (using nil) ->
                        modemPort = Data.readServerData "modem_port"
                        channel = Data.readServerData "network_channel"
                        thisAddress = os.getComputerID!..":"..channel
                        
                        while true
                            data = Network.listen(modemPort, channel) or {}
                            
                            switch data[1]
                                when "test_connection"
                                    Network.send modemPort, .senderAddress, thisAddress, .sourceAddress, {"connection_response"}
                                when "connection_request"
                                    -- TODO: Check whitelist here
                                    if true
                                        modules = Data.readTempData "server_modules"
                                    
                                        for k, v in pairs modules
                                            modules[k].thread = nil
                                        
                                        Network.send modemPort, .senderAddress, thisAddress, .sourceAddress, {"connection_success", modules}
                                    else
                                        Network.send modemPort, .senderAddress, thisAddress, .sourceAddres, {"connection_failure", "not_whitelisted"}
                }
                
                logAndDisplay "Server module loaded: CORE"
                
                -- Load Server Modules from HDD
                loadModuleFiles os.getSystemDir "server"
                -- Load Server Modules from ROM
                loadModuleFiles fs.combine("rom", os.getSystemDir("server")).."/"
                
                Data.writeTempData modules, "server_modules"
            elseif Data.readTempData("parent_address") and Data.readServerData("server_address")
                logAndDisplay "Attempting to connect to server"
                
                serverAddress = Data.readServerData "server_address"
                receiverAddress = Data.readTempData "parent_address"
                sourceAddress = os.getComputerID!..":"..channel
                
                Network.send modemPort, receiverAddress, sourceAddress, serverAddress, {"connection_request"}
                data, err = Network.listen(modemPort, channel, 5) or {}
                
                if data[1] == "connection_success"
                    Data.writeTempData data[2], "server_modules"
                    Data.writeTempData "Side.CLIENT", "current_side"
                    Data.writeServerData .sourceAddress, "server_address"
                    
                    logAndDisplay "Connection established"
                elseif err == "timeout"
                    logAndDisplay "Connection timed out", "warning"
        
    logAndDisplay "Loading Themes"
    theme = Data.readClientData "current_theme"
    if not theme
        theme = "Default"
        Data.writeClientData theme, "current_theme"
    
    themes = {}
    loadThemeFiles = (searchPath) ->
        for i, path in ipairs fs.list searchPath
            if fs.isDir searchPath..path
                name, theme = os.getThemeFromFile searchPath..path
                themes[name] = theme
                logAndDisplay "Theme loaded: "..name
    
    -- Load Theme files from HDD
    loadThemeFiles os.getSystemDir "themes"
    -- Load Theme files from ROM
    loadThemeFiles fs.combine("rom", os.getSystemDir("themes")).."/"
    
    Data.writeTempData themes, "themes"
    
    logAndDisplay "Loading User Interface"
    if Interface.getScreenWidth! < 51 or Interface.getScreenHeight! < 19
        error Interface.getLocalizedString "error.shell.screen_dims"
    if not Term.isColor!
        error Interface.getLocalizedString "error.shell.screen_color"
    
    os.addProcess "SYSTEM_THREAD", ->
        path = os.getSystemDir("client").."startup.lua"
        
        if fs.exists "rom/"..path
            os.run {}, "rom/"..path
        elseif fs.exists path
            os.run {}, path
        else
            error "No startup.lua file found!"
    
    for k, v in pairs modules
        os.addProcess string.upper(k).."_NETWORK_THREAD", v.thread
    
    ok, err, process = os.startProcesses!
    if not ok
        log err, "severe", process
        error "Thread error, dropping to command line"

with commandLine = {}
    .colors = {
        background: Colors.black
        text: Colors.white
        promptText: if Term.isColor! then Colors.lime else Colors.white
        miscText: if Term.isColor! then Colors.yellow else Colors.white
        misc2Text: if Term.isColor! then Colors.cyan else Colors.white
        errorText: if Term.isColor! then Colors.red else Colors.white
    }
    
    -- Display error is OS errored
    Term.setBackgroundColor .colors.background
    Term.setTextColor .colors.errorText
    clear!
    
    if not ok
        log err, "severe"
        print "WolfOS has encountered an issue."
        
        dumpLocation = os.getSystemDir("root").."error_dump.log"
        file = fs.open dumpLocation, "w"
        
        if file
            for k, v in ipairs getLogBuffer!
                file.writeLine "["..v.level.."]["..v.thread.."] "..v.message
            
            file.close!
            Term.setTextColor .colors.text
            print "The error log has been dumped to: "..dumpLocation.."\n"
    
    Term.setTextColor .colors.miscText
    print "Dropping to WolfOS command line.\nType 'help' to view a list of available commands.\n"
    
    .running = true
    .commandHistory = {}
    .currentUser = nil
    .currentPath = ""
    
    .list = (data, color, sort = true) ->
        if not color then color = .colors.misc2Text
        
        if sort
            table.sort data, (a, b) ->
                if not string.find(a, " ") and string.find(b, " ")
                    return true
                elseif string.find(a, " ") and not string.find(b, " ")
                    return false
                else
                    return a < b
        
        for k, v in ipairs data
            Term.setTextColor color
            print v
            
            x, y = Term.getCursorPos!
            w, h = Term.getSize!
            
            if y == h
                Term.setTextColor .colors.promptText
                Term.write "Press any key to continue..."
                os.pullEvent "key"
                Term.clearLine!
                Term.setCursorPos 1, y
    
    .commands = {
        exit: -> .running = false
        version: -> print "WolfOS "..os.getVersion!
        info: -> print "Copyright 2013 James Chapman (toxic.wolf666@gmail.com)"
        clear: -> clear!
        apis: ->
            apis = {}
            for k, v in pairs getfenv 0
                if type(v) == "table" and k != "_G"
                    table.insert apis, k
            .list apis
        functions: (api) ->
            if type(api) == "string"
                t = getfenv(0)[api]
                if t
                    functions = {}
                    for k, v in pairs t
                        if type(v) == "funtion"
                            table.insert functions, k
                    .list functions
                elseif api
                    printError "Unknown api: "..api
            else
                printError "Usage: functions <api>"
        log: ->
            buffer = getLogBuffer!
            for k, v in ipairs buffer
                t = "["..v.level.."]["..v.thread.."] "..v.message
                color = if string.find(t, "%[WARNING%]") or string.find(t, "%[SEVERE%]") then .colors.errorText else .colors.misc2Text
                .list {t}, color, false
        lua: (script) ->
            if .currentUser and .currentUser.type == "admin"
                luaRunning = true
                commandHistory = {}
                env = {
                    exit: ->
                        luaRunning = false
                        debug.clear!
                }
                setmetatable env, {__index: getfenv 0}
                
                Term.setTextColor .colors.miscText
                print "Interactive Lua prompt.\nCall 'exit()' to exit.\n"
                
                while luaRunning
                    Term.setTextColor .colors.promptText
                    write "lua> "
                    Term.setTextColor .colors.text
                    
                    s = ""
                    if script
                        s = "os.run({}, \""..script.."\")"
                        print s
                        script = nil
                    else
                        s = read nil, commandHistory
                    
                    table.insert commandHistory, s
                    Term.settextColor .colors.miscText
                    
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
                            Term.setTextColor .colors.miscText
                            Term.setBackgroundColor .colors.background
                            if Term.getCursorPos! > 1
                                print!
                            while (results[n + 1] != nill) or (n <= forcePrint)
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
    .commands.help = ->
        commands = {}
        for k, v in pairs .commands
            if type(v) == "table"
                for _k, _v in pairs v
                    if type(_v) == "function"
                        table.insert commands, k.." ".._k
            elseif type(v) == "function"
                table.insert commands, k
        .list commands
    
    .run = (...) ->
        args = {...}
        
        if type(.commands[args[1]]) == "table"
            set = table.remove args, 1
            command = table.remove args, 1
            
            if type(.commands[set][command]) == "function"
                return .commands[set][command] unpack args
            else
                printError "Unknown command: "..set.." "..(command or "")
        elseif type(.commands[args[1]]) == "function"
            command = table.remove args, 1
            return .commands[command] unpack args
        elseif args[1]
            printError "Unknown command: "..args[1]
    
    .parseLine = (line) ->
        words = {}
        for match in string.gmatch line, "[^ \t]+"
            table.insert words, match
        
        return .run unpack words
    
    while .running
        Term.setBackgroundColor .colors.background
        Term.setTextColor .colors.promptText
        if Term.getCursorPos! > 1
            print!
        
        if .currentPath
            write .currentPath
        write "> "
        Term.setTextColor .colors.text
        
        s = read nil, .commandHistory
        table.insert .commandHistory, s
        
        Term.setTextColor .colors.miscText
        .parseLine s

os.shutdown!
