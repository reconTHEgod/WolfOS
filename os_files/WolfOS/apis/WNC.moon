-- WolfOS Network Communication (HyperPaw)

encryptData = (receiver, port, data) ->
    sender = os.getComputerID!
    return sender.."."..receiver.."."..port..":"..crypt.toBase64 data

decryptData = (data) ->
    f = string.gmatch data, "[^%.]"
    sender = f!
    receiver = f!
    port = f!
    data = data\sub string.find(data, ":") + 1
    return sender, receiver, port, crypt.fromBase64 data

export send = (receiver, port, ...) ->
    rednet.send receiver, encryptData receiver, port, textutils.serialize {...}

export receive = (timeout, senderFilter, exlude = false) -> -- exclude: true = exclude Sender IDs, false = include Sender IDs
    timer = if type(timeout) == "number"
        os.startTimer timeout
    if type(senderFilter) == "number"
        senderFilter = {senderFilter}
    
    while true
        event, p1, p2, p3 = os.pullEvent!
        if event == "rednet_message"
            sender, receiver, port, data = decryptData p2
            if receiver == os.getComputerID!
                match = WDM.util.matchFromTable senderFilter, sender
                if not senderFilter or (exclude == true and not match) or (exclude == false and match)
                    return sender, port, p3, unpack textutils.unserialize data
        elseif event == "timer" and p1 == timer
            return nil, nil, nil, "timeout"
