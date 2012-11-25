-- WolfOS Shell

ok, err = pcall ->
    if not os.getComputerLabel!
        os.setComputerLabel "ID# "..os.getComputerID!
    
    -- API loading
    debug.print "Initializing WolfOS "..os.getVersion!.."...\n"
    debug.print "Loading System APIs...\n"
    sleep 0.01
    for _, api in ipairs fs.list os.getSystemDir "apis"
        if not fs.isDir fs.combine os.getSystemDir("apis"), api
            if not string.find api, ".moon"
                os.loadAPI os.getSystemDir("apis")..api
                debug.print "System API loaded: "..api\sub 1, (string.find(api, "%.") or #api + 1) - 1
    debug.print!
    
    -- Checking integrity of data files
    if not WDM.exists os.getSystemDir("data").."client.dat"
        WDM.write os.getSystemDir("data").."client.dat", crypt.toBase64 textutils.serialize {}
    if not WDM.exists os.getSystemDir("data").."server.dat"
        WDM.write os.getSystemDir("data").."server.dat", crypt.toBase64 textutils.serialize {}
    
    -- Opening modem port
    modemPort = WDM.data.readClientData "modem_port"
    if modemPort
        if WPH.getType(modemPort) != "modem"
            WDM.data.writeClientData nil, "modem_port"
            WDM.data.writeClientData false, "online"
        elseif WDM.data.readClientData "online"
            rednet.open modemPort
            debug.print "Opened modem port: "..modemPort.."\n"
    
    -- Loading Server modules
    debug.print "Initializing Server...\n"
    loadModule = (path, port) ->
        name = fs.getName path
        WDM.writeTempData name\sub(1, (string.find(name, "%.") or #moduleName + 1) - 1), "network_port: 0"
        return ->
            os.run {}, path, port
    modules = {}
    i = 1
    for _, module in ipairs fs.list os.getSystemDir "server"
        path = os.getSystemDir("server")..module
        if not fs.isDir(path) and not string.find module, ".moon"
            table.insert modules, loadModule path, i
            i += 1
            debug.print "Server module loaded: "..module\sub 1, (string.find(module, "%.") or #module + 1) - 1
    debug.print!
    
    -- Syncing monitor ports
    debug.print "Initializing monitors...\n"
    sync.redirect true
    
    monitors = WDM.data.readClientData "monitors"
    if not monitors
        monitors = {}
        WDM.data.writeClientData monitors, "monitors"
    for monitorPort, b in pairs monitors
        if WPH.getType(monitorPort) == "monitor"
            if b == true
                sync.addMonitor monitorPort
                debug.print "Syncronised monitor port: "..monitorPort
        else
            monitors[monitorPort] = nil
    WDM.data.writeClientData monitors, "monitors"
    
    debug.print "\nLoading User Interface..."
    sleep 0.01
    
    -- Display boot logo
    frame = WUI.frame.Frame "logo_frame"
    if term.isColour!
        frame\setBackgroundColour colours.grey
    
    graphic = WUI.objects.Graphic "logo_graphic", WUI.getScreenWidth!, WUI.getScreenHeight!
    if term.isColour!
        graphic\setGraphic os.getSystemDir("client").."logo.nfp"
    else
        graphic\setGraphic os.getSystemDir("client").."logo_monochrome.nfp"
    
    label = WUI.objects.Label "logo_label", WUI.getScreenWidth!
    label\setText "WolfOS "..os.getVersion!.." - toxic.wolf@hotmail.co.uk"
    label\setTextAlign "center"
    if term.isColour!
        label\setTextColour colours.lightGrey
        label\setBackgroundColour colours.grey
    
    frame\add graphic, 1, 1
    frame\add label, 1, 17
    frame\redraw!
    sleep 3
    
    parallel.waitForAny -> 
            os.run {}, os.getSystemDir("client").."startup.lua",
        -> -- Core Server module (network_port: 0)
            while true
                if WDM.data.readClientData "online"
                    sender, port, distance, p = WNC.receive 2
                    switch p
                      when "client_connection"
                            if WDM.data.readServerData "server_state"
                                WNC.send sender, port, "connection_success"
                      when "test_connection"
                            WNC.send sender, port, "connection_response"
                else
                    sleep 2,
        unpack modules

-- Drop to command line if init failed and display error
if not ok
    running = true
    commandHistory = {}
    
    -- Command line colours
    backgroundColour = colours.black
    userText = colours.white
    promptText = colours.white
    text = colours.white
    if term.isColour!
        promptText = colours.lime
        text = colours.yellow
    
    list = (table) ->
        for k, v in ipairs table
            debug.print v
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
        version: -> debug.print "WolfOS "..os.getVersion!
        clear: ->
            term.clear!
            term.setCursorPos 1, 1
        apis: ->
            apis = {}
            for k, v in pairs getfenv 0
                if type(v) == "table" and k != "_G"
                    table.insert apis, k
            list apis
                    
        modules: (api) ->
            if getfenv(0)[api] and api != "_G"
                modules = {}
                for k, v in pairs getfenv(0)[api]
                    if type(v) == "table"
                        table.insert modules, k
                list modules
            elseif api
                debug.printError "Unknown api: "..api
            else
                debug.printError "Usage: modules <api>"
        functions: (api, module) ->
            t = getfenv(0)[api]
            if t and api != "_G"
                if module
                    t = t[module]
                if t
                    functions = {}
                    for k, v in pairs t
                        if type(v) == "function"
                            table.insert functions, k
                    list functions
                elseif module
                    debug.printError "Unknown module: "..api.."."..module
            elseif api
                debug.printError "Unknown api: "..api
            else
                debug.printError "Usage: functions <api> [module]"
        shutdown: -> os.shutdown!
        reboot: -> os.reboot!
    }
    commands.help = ->
        _commands = {}
        for k, _ in pairs commands
            table.insert _commands, k
        list _commands
    
    run = (_command, ...) ->
        if commands[_command]
            return commands[_command] ...
        else
            debug.printError "Unknown command: ".._command
    
    parseLine = (_line) ->
        words = {}
        for match in string.gmatch _line, "[^ \t]+"
            table.insert words, match
        
        command = words[1]
        if command
            return run command, unpack words, 2
    
    term.setBackgroundColour backgroundColour
    term.setTextColour userText
    debug.clear!
    if err
        debug.print "An error occured during initialization:"
        debug.printError err
    else
        debug.print "An unknown error occured during initialization."
    debug.print "\nDropping to WolfOS command line.\nType 'help' to view a list of available commands.\n"
    
    -- Read commands and execute them
    while running
        term.setBackgroundColour backgroundColour
        term.setTextColour promptText
        if term.getCursorPos! > 1
            debug.print!
        debug.write "> "
        term.setTextColour userText
        
        s = debug.read nil, commandHistory
        table.insert commandHistory, s
        
        term.setTextColour text
        parseLine s

os.shutdown! -- Just in case.
