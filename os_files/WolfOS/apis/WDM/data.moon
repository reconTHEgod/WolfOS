-- WolfOS Data Management Library
-- Data Module

dataTemp = {}
dataClient = nil
dataServer = nil

readData = (path) ->
    return textutils.unserialize crypt.fromBase64 WUI.readAll path

writeData = (path, table) ->
    WUI.write path, crypt.toBase64 textutils.serialize table

export readTempData = (k) ->
    if k
        return dataTemp[k]
    return dataTemp

export readClientData = (k) ->
    if not dataClient
        dataClient = readData os.getSystemDir("data").."client.dat"
    if k
        return dataClient[k]
    return dataClient

export readServerData = (k) ->
    if not dataServer
        dataServer = readData os.getSystemDir("data").."server.dat"
    if k
        return dataServer[k]
    return dataServer

export writeTempData = (v, k) ->
    if k
        dataTemp[k] = v
    elseif type(v) == "table"
        dataTemp = v

export writeClientData = (v, k) ->
    if not dataClient
        dataClient = readData os.getSystemDir("data").."client.dat"
    if k
        dataClient[k] = v
    elseif type(v) == "table"
        dataClient = v
    writeData os.getSystemDir("data").."client.dat", dataClient

export writeServerData = (v, k) ->
    if not dataServer
        dataServer = readData os.getSystemDir("data").."server.dat"
    if k
        dataServer[k] = v
    elseif type(v) == "table"
        dataServer = v
    writeData os.getSystemDir("data").."server.dat", dataServer
