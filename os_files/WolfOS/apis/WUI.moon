-- WolfOS User Interface Library

WDM = require os.getSystemDir("apis").."WDM..lua"

export getLocalisedString = (key) ->
    lang = WDM.readTempData "localisation"
    s = lang\gmatch("<entry key=\""..key.."\">(.-)</entry>")!
    
    if s and s != ""
        return s
    return key

export write = (key) ->
    return debug.write getLocalisedString key

export print = (key) ->
    return debug.print getLocalisedString key

export getScreenWidth = ->
    w = term.getSize!
    return w

export getScreenHeight = ->
    _, h = term.getSize!
    return h
