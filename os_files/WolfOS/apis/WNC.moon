-- WolfOS Network Communication (HyperPaw)

peripheral = require "rom.apis.peripheral"
textutils = require "rom.apis.textutils"
crypt = require os.getSystemDir("apis").."crypt..lua"
WDM = require os.getSystemDir("apis").."WDM..lua"

_VALID_PORTS = {top: true, bottom: true, front: true, back: true, left: true, right: true}

export send = (modemPort, address, ...) ->
    ok, err = ftype "string, string", modemPort, address
    if not ok
        error err, 2
    
    channel = tonumber address\gmatch("(%d+)$")!
    data = {senderAddress: WDM.readTempData("address")..":"..channel, receiverAddress: address}
    
    packets = {...}
    for k, v in ipairs packets
        table.insert data, v
    
    modem = {}
    if _VALID_PORTS[modemPort]
        if peripheral.getType(modemPort) == "modem"
            modem = peripheral.wrap modemPort
        else
            error "Invalid modem port", 2
    else
        error "Invalid modem port", 2
    
    if not modem.isOpen channel
        modem.open channel
    
    modem.transmit channel, channel, crypt.toBase64 textutils.serialize data
    modem.close channel
    

export listen = (modemPort, channel, timeout) ->
    ok, err = ftype "string, +number, ?+number", modemPort, channel, timeout
    if not ok
        error err, 2
    if channel > 65535
        error, "Invalid channel number", 2
    
    modem = {}
    if _VALID_PORTS[modemPort]
        if peripheral.getType(modemPort) == "modem"
            modem = peripheral.wrap modemPort
        else
            error "Invalid modem port", 2
    else
        error "Invalid modem port", 2
    
    if not modem.isOpen channel
        modem.open channel
    
    timer = if timeout
        os.startTimer timeout
    
    while true
        _event, _modemPort, _channel, _replyChannel, _data, _distance = os.pullEvent!
        
        if _event == "modem_message"
            data = textutils.unserialize crypt.fromBase64 _data
            data.distance = _distance
            
            if data.receiverAddress == WDM.readTempData("address")..":"..channel
                    modem.close channel
                    return data, nil
        elseif _event == "timer"
            _timer = _modemPort
            if _timer == timer
                modem.close channel
                return nil, "timeout"
