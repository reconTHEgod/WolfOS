-- HyperPaw Network Relay Shell

term = require "rom.apis.term"
textutils = require "rom.apis.textutils"
peripheral = require "rom.apis.peripheral"
crypt = require os.getSystemDir("apis").."crypt..lua"
WNC = require os.getSystemDir("apis").."WNC..lua"

import clear, print, printError, read, write from debug

if not os.getComputerLabel!
    os.setComputerLabel "ID #"..os.getComputerID!


-- Initialise data storage
computerID = os.getComputerID!
update = false

relays = {}
links = {}
parents = {}

systemData = {}
data_ = {}
data_.file_path = os.getSystemDir("data").."network.dat"
data_.write = ->
    file = fs.open data_.file_path, "w"
    file.write crypt.toBase64 textutils.serialize systemData
    file.close!
data_.read = ->
    file = fs.open data_.file_path, "r"
    systemData = textutils.unserialize crypt.fromBase64 file.readAll!
    file.close!

-- Network Map functions
map = {}
map.add_relay = (id) ->
    relays[id] = {id: id, dist: -1, pre: -1}
    links[id] = {}
map.add_link = (id1, id2) ->
    if relays[id1] == nil then map.add_relay id1
    if relays[id2] == nil then map.add_relay id2
    
    n1 = math.min id1, id2
    n2 = math.max id1, id2
    if links[n1][n2] == nil
        links[n1][n2] = true
        return true
    return false
map.get = ->
    return {links: links, parents: parents}
map.distribute = ->
    network_map = map.get!
    for n1, link in pairs links
        for n2 in pairs link
            if n1 == computerID
                WNC.send systemData.modem_port, n2, n1, n2, {"HYPERPAW_network_map_update", network_map}
            elseif n2 == computerID
                WNC.send systemData.modem_port, n1, n2, n1, {"HYPERPAW_network_map_update", network_map}
map.process_update = (network_map) ->
    _update = false
    
    for id1, id2 in pairs network_map.links
        _update = map.add_link id1, id2
    
    for id1, id2 in pairs network_map.parents
        if parents[id1] != id2
            parents[id1] = id2
            _update = true
    
    return _update
-- Dijksta's algorithm
map.calculate = ->
    Q, Qsize, i, relay, minDist, minIndex, id, u, v, alt = {}, 0
    for i, relay in pairs relays
        table.insert Q, relay.id
        Qsize += 1
        relay.pre = -1
        relay.dist = -1
    
    relays[computerID].dist = 0
    
    while Qsize > 0
        minDist = -1
        minIndex = -1
        for i, id in pairs Q
            if relays[id].dist >= 0 and (relays[id].dist < minDist or minDist == -1)
                midDist = relays[id].dist
                u = id
                minIndex = i
        
        if minDist == -1
            return false
        
        table.remove Q, minIndex
        Qsize -= 1
        
        for i, v in pairs Q
            if links[math.min(u, v)][math.max(u, v)]
                alt = relays[u].dist + 1
                if alt < relays[v].dist or relays[v].dist == -1
                    relays[v].dist = alt
                    relays[v].pre = u

get_nexthop_to = (relay) ->
    next = nil
    while relays[relay].pre != -1
        next = relay
        relay = relays[relay].pre
    return next

_INIT_THREAD = ->
    _path = ""
    for path in os.getSystemDir("data")\gmatch "%w+"
        _path ..= path.."/"
        if not fs.exists _path
            fs.makeDir _path
    
    if not fs.exists data_.file_path
        data_.write!
    
    data_.read!
    modemPort = systemData.modem_port or ""
    if not peripheral.getType(modemPort) == "modem"
        systemData.connected = false
        data_.write!
        

_COMMUNICATION_THREAD = ->
    if systemData.connected
        modemPort = systemData.modem_port
        channel = systemData.network_channel
        
        map.add_relay computerID
        modem = peripheral.wrap modemPort
        modem.open channel
        WNC.broadcast modemPort, channel, {"HYPERPAW_relay_discovery"}
        
        thisAddress = computerID..":"..channel
        while true
            data = WNC.listen modemPort, channel
            
            if data.senderAddress == nil or data.sourceAddress == nil
                error "Attempt to process illegal packet", 0
            
            sender = data.senderAddress
            senderID = tonumber sender\match "(%d+)"
            dest = data.destinationAddress
            destID = nil
            if dest then destID = tonumber dest\match "(%d+)"
            
            if data.destinationAddress == nil
                if data[1] == "HYPERPAW_parent_request"
                    WNC.send modemPort, sender, thisAddress, sender, {"HYPERPAW_parent_proposal"}
                elseif data[1] == "HYPERPAW_relay_discovery"
                    if relays[senderID] == nil
                        map.add_relay senderID
                    
                    update = map.add_link computerID, senderID
                    if not update
                        WNC.send modemPort, sender, thisAddress, sender, {"HYPERPAW_network_map_update", map.get!}
            elseif data.destinationAddress == thisAddress
                if data[1] == "HYPERPAW_network_map_update"
                    update = map.process_update data[2]
                elseif data[1] == "HYPERPAW_child_registry"
                    if parents[senderID] == nil or parents[senderID] != computerID
                        parents[senderID] = computerID
                        update = true
                elseif data[1] == "HYPERPAW_network_map_request"
                    WNC.send modemPort, sender, thisAddress, data.sourceAddress, {"HYPERPAW_network_map_update", map.get!}
            else
                sendTo = -1
                if parents[senderID] != nil
                    if sender != data.sourceAddress
                        WNC.send modemPort, sender, thisAddress, sender, {"HYPERPAW_relay_error", "impersonation_attempt"}
                
                if parents[destID] != nil
                    if parents[destID] == computerID
                        sendTo = destID
                    else
                        sendTo = get_next_hop_to parents[destID]
                elseif relays[destID] != nil
                    sendTo = get_next_hop_to destID
                
                if sendTo > -1
                    packets = {}
                    for k, v in ipairs data
                        table.insert packets, v
                    
                    WNC.send modemPort, tostring(sendTo)..":"..channel, data.sourceAddress, dest, packets
                else
                    error "Unable to relay from "..sender
            
            if update
                --map.calculate!
                map.distribute!
                update = false

_SYSTEM_THREAD = ->
    print "HyperPaw Network Relay\nType 'help' to view a list of available commands.\n"
    
    running = true
    commandHistory = {}
    
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
                --os.pullEvent "key"
                term.clearLine!
                term.setCursorPos 1, y
    
    -- Table of commands
    commands = {
        exit: -> running = false
        clear: -> clear!
        shutdown: -> os.shutdown!
        reboot: -> os.reboot!
        info: ->
            print "HyperPaw Networking - in association with WolfOS.\nCopyright 2013 James Chapman (toxic.wolf666@gmail.com)"
        host: (modemPort, channel) ->
            if not systemData.connected
                cont = false
                if modemPort == "top" or modemPort == "bottom" or modemPort == "front" or modemPort == "back" or modemPort == "left" or modemPort == "right"
                    if peripheral.getType(modemPort) == "modem"
                        systemData.modem_port = modemPort
                        data_.write!
                        cont = true
                
                channel = tonumber channel
                if cont and channel and channel < 65535
                    systemData.network_channel = channel
                    data_.write!
                    cont = true
                else
                    cont = false
                
                if cont
                    systemData.connected = true
                    data_.write!
                    os.addProcess "COMMUNICATION_THREAD", _COMMUNICATION_THREAD
                    print "Hosting network relay point..."
                else
                    printError "Usage: connect <modem port> <channel>"
            else
                printError "Already hosting network relay point!"
        close: ->
            if systemData.connected
                modem = peripheral.wrap networkData.modem_port
                modem.closeAll!
                os.removeProcess "COMMUNICATION_THREAD"
                print "Disconnected from network."
                
            systemData.connected = false
            data_.write!
        status: ->
            s = ""
            for id1, id2 in pairs parents
                if id2 == computerID
                    s ..= tostring id1..", "
            data = {
                "Hosting: "..tostring systemData.connected
                "Network channel: "..tostring systemData.network_channel
                "Modem port: "..tostring systemData.modem_port
                "\nChildren:"
                s
            }
            list data, false
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
        if term.getCursorPos! > 1
            print!
        write "> "
        
        s = read nil, commandHistory
        table.insert commandHistory, s
        
        parseLine s

os.addProcess "INIT_THREAD", _INIT_THREAD
os.addProcess "SYSTEM_THREAD", _SYSTEM_THREAD
os.addProcess "COMMUNICATION_THREAD", _COMMUNICATION_THREAD

ok, err = os.startProcesses!
if not ok
    error err
