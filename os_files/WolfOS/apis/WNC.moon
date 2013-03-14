-- WolfOS Network Communication (HyperPaw)

textutils = require "rom.apis.textutils"
crypt = require os.getSystemDir("apis").."crypt..lua"

_VALID_PORTS = {top: true, bottom: true, front: true, back: true, left: true, right: true}

export send = (modemPort, channel, replyChannel, ...) ->
    ok, err = ftype "string, +number, +number", modemPort, channel, replyChannel
    if not ok
        error err, 2
    
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
    
    modem.transmit channel, replyChannel, crypt.toBase64 textutils.serialize {...}
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
            data = crypt.fromBase64 _data
            
            if _channel == channel
                    modem.close channel
                    return _replyChannel, _distance, unpack(textutils.unserialize(data))
        elseif _event == "timer"
            _timer = _modemPort
            if _timer == timer
                modem.close channel
                return nil, nil, "timeout"
