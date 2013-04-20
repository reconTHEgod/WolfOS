-- WolfOS Network Communication (HyperPaw)

peripheral = require "rom.apis.peripheral"
textutils = require "rom.apis.textutils"
crypt = require os.getSystemDir("apis").."crypt..lua"

_VALID_PORTS = {top: true, bottom: true, front: true, back: true, left: true, right: true}

parseAddress = (address) ->
    address = {string.match address, "(%d+):(%d+)"}
    
    if #address != 2 or not (tonumber(address[2]) <= 65535)
        error "Invalid network address", 3
    return address

export checkModemPort = (modemPort) ->
    if _VALID_PORTS[modemPort]
        if peripheral.getType(modemPort) == "modem"
            return true, peripheral.wrap modemPort
        else
            return false, "Invalid modem port"
    else
        return false, "Invalid modem port"

export send = (modemPort, receiverAddress, sourceAddress, destinationAddress, packets) ->
    ok, err = ftype "string, string, string, string, table", modemPort, receiverAddress, sourceAddress, destinationAddress, packets
    if not ok
        error err, 2
    
    address = parseAddress receiverAddress
    if not address
        error "Invalid network channel", 2
    _address = parseAddress destinationAddress
    if not _address
        error "Invalid network channel", 2
    _address = parseAddress sourceAddress
    if not _address
        error "Invalid network channel", 2
    
    channel = tonumber address[2]
    data = {
        senderAddress: os.getComputerID!..":"..channel
        receiverAddress: receiverAddress
        sourceAddress: sourceAddress
        destinationAddress: destinationAddress
    }
    
    for k, v in ipairs packets
        table.insert data, v
    
    ok, modem = checkModemPort modemPort
    if not ok
        error modem, 2
    
    if not modem.isOpen channel
        modem.open channel
    
    modem.transmit channel, channel, crypt.toBase64 textutils.serialize data
    modem.close channel

export broadcast = (modemPort, channel, packets) ->
    ok, err = ftype "string, +number, table", modemPort, channel, packets
    if not ok
        error err, 2
    if channel > 65535
        error "Invalid network channel", 2
    
    address = os.getComputerID!..":"..channel
    data = {
        senderAddress: address
        sourceAddress: address
    }
    
    for k, v in ipairs packets
        table.insert data, v
    
    ok, modem = checkModemPort modemPort
    if not ok
        error modem, 2
    
    if not modem.isOpen channel
        modem.open channel
    
    modem.transmit channel, channel, crypt.toBase64 textutils.serialize data
    modem.close channel
    
export listen = (modemPort, channel, timeout) ->
    ok, err = ftype "string, +number, ?+number", modemPort, channel, timeout
    if not ok
        error err, 2
    if channel > 65535
        error "Invalid network channel", 2
    
    ok, modem = checkModemPort modemPort
    if not ok
        error modem, 2
    
    timer = if timeout
        os.startTimer timeout
    
    while true
        if not modem.isOpen channel
            modem.open channel
        
        _event, _modemPort, _channel, _replyChannel, _data, _distance = os.pullEvent!
        
        if _event == "modem_message"
            data = textutils.unserialize crypt.fromBase64 _data
            data.distance = _distance
            
            if data.receiverAddress == nil or data.receiverAddress == os.getComputerID!..":"..channel
                    modem.close channel
                    return data, nil
        elseif _event == "timer"
            _timer = _modemPort
            if _timer == timer
                modem.close channel
                return nil, "timeout"
