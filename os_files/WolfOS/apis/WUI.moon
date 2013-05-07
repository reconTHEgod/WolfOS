-- WolfOS User Interface Library

WDM = os.getApiSided "WDM"

export getLocalisedString = (key) ->
    s = WDM.readTempData("localisation")[WDM.readClientData("current_locale")][key]
    
    if s and s != ""
        return s
    return key

export getScreenWidth = ->
    w = term.getSize!
    return w

export getScreenHeight = ->
    _, h = term.getSize!
    return h
