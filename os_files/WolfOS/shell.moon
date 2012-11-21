-- WolfOS Shell

ok, err = pcall ->
    if not os.getComputerLabel!
        os.setComputerLabel "ID# "..os.getComputerID!
    
    debug.print "Initializing WolfOS "..os.getVersion!.."...\n"
    debug.print "Loading System APIs...\n"
    sleep 0.01
    for _, api in ipairs fs.list os.getSystemDir "apis"
        if not fs.isDir fs.combine os.getSystemDir("apis"), api
            if not string.find api, ".moon"
                os.loadAPI os.getSystemDir("apis")..api
                debug.print "System API loaded: "..api\sub 1, (string.find(api, "%.") or #api + 1) - 1

    -- Extra init stuff goes here
    
    debug.print "\nLoading User Interface..."
    sleep 0.01
    
    os.run {}, os.getSystemDir("client").."startup.lua"

-- Drop to command line if init failed and display error
if not ok
    debug.clear!
    if err
        debug.print "An error occured during initialization:"
        debug.printError err
    else
        debug.print "An unknown error occured during initialization."
    debug.print "\nDropping to WolfOS command line.\nType 'help' to view a list of available commands.\n"
    
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
    
    -- Table of commands
    commands = {
        exit: -> running = false
        apis: ->
            term.setTextColour text
            for api, v in pairs getfenv 0
                if type(v) == "table" and api != "_G"
                    debug.write api.."\n"
                    x, y = term.getCursorPos!
                    w, h = term.getSize!
                    if y == h
                        os.pullEvent "key"
        modules: (api) ->
            if getfenv(0)[api] and api != "_G"
                term.setTextColour text
                for module, v in pairs getfenv(0)[api]
                    if type(v) == "table"
                        debug.write module.."\n"
                        x, y = term.getCursorPos!
                        w, h = term.getSize!
                        if y == h
                            os.pullEvent "key"
            elseif api
                debug.printError "Unknown api: "..api
            else
                debug.printError "Usage: modules <api>"
        shutdown: -> os.shutdown!
        reboot: -> os.reboot!
    }
    commands.help = ->
        term.setTextColour text
        for command, _ in pairs commands
            debug.write command.."\n"
            x, y = term.getCursorPos!
            w, h = term.getSize!
            if y == h
                os.pullEvent "key"
    
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
        parseLine s

os.shutdown! -- Just in case.
