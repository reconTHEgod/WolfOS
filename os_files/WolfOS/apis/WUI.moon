-- WolfOS User Interface Library

WDM = os.getApi "WDM"

export getLocalisedString = (key) ->
    s = WDM.readTempData("localisation")[WDM.readClientData("current_locale")][key]
    
    if s and s != ""
        return s
    return key

export getValueInTheme = (key) ->
    s = WDM.readTempData("themes")[WDM.readClientData("current_theme")][key]
    
    if s and s != ""
        return s
    return WDM.readTempData("themes")["Default"][key]

export getFileInTheme = (key) ->
    theme = WDM.readTempData("themes")[WDM.readClientData("current_theme")]
    
    if theme[key]
        return fs.combine theme.__path, theme[key]
    else
        theme = WDM.readTempData("themes")["Default"]
        return fs.combine theme.__path, theme[key]

export getScreenWidth = ->
    w = term.getSize!
    return w

export getScreenHeight = ->
    _, h = term.getSize!
    return h

-----------------------------------------

colours = require "rom.apis.colours"
paintutils = require "rom.apis.paintutils"

env = getfenv paintutils.loadImage
env.io = require "rom.apis.io"
setfenv paintutils.loadImage, env

checkColour = (c) ->
    if type(c) != "number"
        c = colours[c]
    if c
        return c
    return 0

fill = (x1 = 0, x2 = 0, y1 = 0, y2 = 0, c) ->
    c = checkColour c
    for x = x1, x2
        for y = y1, y2
            if c > 0
                paintutils.drawPixel x, y, c

setBackgroundColour = (c) ->
    c = checkColour c
    term.setBackgroundColour c

setTextColour = (c) ->
    c = checkColour c
    term.setTextColour c

write = (t = "", x = 1, y = 1, ct, cb) ->
    term.setCursorPos x, y
    if ct then setTextColour ct
    if cb then setBackgroundColour cb
    term.write t

clear = (c) ->
    if c
        setBackgroundColour c
    else
        setBackgroundColour "black"
    term.clear!
    term.setCursorPos 1, 1

-- Parent Class

class Object
    setColour: (k, v) =>
        c = checkColour v
        @data.colour[k] = c
    
    setEnabled: (b) =>
        ok, err = ftype "boolean", b
        if @data.isEnabled != nil and ok
            @data.isEnabled = b
        elseif not ok
            error err, 2
    
    setEventHandler: (k, f) =>
        ok, err = ftype "string, function", k, f
        if not @type("FRAME") and @data.eventHandlers[k] and ok
            @data.eventHandlers[k] = f
        elseif not ok
            error err, 2
        else
            error "Attempt to register invalid eventHandler", 2
    
    setPosition: (x, y) =>
        ok, err = ftype "+number, +number", x, y
        if ok    
            @data.xPos, @data.yPos = x, y
        else
            error err, 2
    
    setSize: (w, h) =>
        ok, err = ftype "+number, +number", w, h
        if ok  
            @data.width, @data.height = w, h
        else
            error err, 2
    
    setText: (t) =>
        ok, err = ftype "table", t
        if @data.text and ok
            @data.text = t
        elseif not ok
            error err, 2
    
    setVisible: (b) =>
        ok, err = ftype "boolean", b
        if ok
            @data.isVisible = b
        else
            error err, 2
    
    type: (s) =>
        if s
            if @data.type == "Object."..s
                return true
        else
            if @data.type\find("^Object.")
                return true

-- Object Classes

class Button extends Object
    new: =>
        @data =
            type: "Object.BUTTON"
            text: {}
            colour: {}
            width: 0
            height: 0
            xPos: 0
            yPos: 0
            isEnabled: true
            isVisible: false
            eventHandlers: {
                onClick: (button) =>
                onDrag: (button, direction) =>
                onFocusGained: =>
                onFocusLost: =>
                onMonitorTouch: (monitorPort) =>
            }
    
    autoWidth: =>
        if @data.text
            i = 0
            for k, v in ipairs @data.text
                if v and v\len! > i
                    i = v\len!
            return i
    
    autoHeight: =>
        return #@data.text

class Label extends Object
    new: =>
        @data =
            type: "Object.LABEL"
            text: {}
            colour: {}
            width: 0
            height: 0
            xPos: 0
            yPos: 0
            isEnabled: true
            isVisible: false
    
    autoWidth: =>
        if @data.text
            i = 0
            for k, v in ipairs @data.text
                if v and v\len! > i
                    i = v\len!
            return i
        
    autoHeight: =>
        return #@data.text

class Image extends Object
    new: =>
        @data =
            type: "Object.IMAGE"
            pixels: {}
            width: 0
            height: 0
            xPos: 0
            yPos: 0
            isEnabled: true
            isVisible: false
            customRenderer: =>
                for y = 1, @data.height
                    for x = 1, @data.width
                        c = @data.pixels[y][x]
                        if c > 0
                            paintutils.drawPixel @data.xPos + x - 1, @data.yPos + y - 1, c
                        if not @data.pixels[y][x + 1] then break
                    if not @data.pixels[y + 1] then break
    
    setImage: (path) =>
        @data.pixels = paintutils.loadImage path
        @data.width = @autoWidth!
        @data.height = @autoHeight!
    
    autoWidth: =>
        if @data.pixels
            i = 0
            for k, v in ipairs @data.pixels
                if v and #v > i
                    i = #v
            return i
        return 0
    
    autoHeight: =>
        if @data.pixels
            return #@data.pixels
        return 0

-- Frame Class

class Frame extends Object
    new: =>
        @data =
            type: "Object.FRAME"
            colour: {}
            width: getScreenWidth!
            height: getScreenHeight!
            xPos: 1
            yPos: 1
            objects: {}
            isEnabled: true
            isVisible: false
            eventHandlers: {
                onClick: (button) =>
                onDrag: (button, oldX, oldY, newX, newY) =>
                    moveX, moveY = newX - oldX, newY - oldY
                    newXPos, newYPos = @data.xPos + moveX, @data.yPos + moveY
                    if newXPos + @data.width - 1 <= getScreenWidth! and newYPos + @data.height - 1 <= getScreenHeight! and newXPos > 0 and newYPos > 0
                        @setPosition newXPos, newYPos
                        clear!
                        @draw!
                onFocusGained: =>
                onFocusLost: =>
                onMonitorTouch: (monitorPort) =>
                onScroll: (direction) =>
            }
            eventListener: false
    
    add: (object) =>
        if object\type!
            object.data.parent = @data
            table.insert @data.objects, object
    
    addEventListener: =>
        @data.eventListener = true
        
        while @data.eventListener
            event, arg1, arg2, arg3 = os.pullEvent()
            
            callEventHandler = (object, x1, x2, y1, y2) ->
                if object.data.eventHandlers and object.data.isEnabled and object.data.isVisible
                    switch event
                        when "mouse_click"
                            if object.data.eventHandlers.onClick and arg2 >= x1 and arg3 >= y1 and arg2 <= x2 and arg3 <= y2
                                object.data.hasFocus = true
                                object.data.eventHandlers.onFocusGained object
                                object.data.eventHandlers.onClick object, arg1
                            else
                                object.data.hasFocus = false
                                object.data.eventHandlers.onFocusLost object
                        when "mouse_drag"
                            if object.data.eventHandlers.onDrag and object.data.hasFocus
                                if object.data.eventBuffer.event == "mouse_click" or object.data.eventBuffer.event == "mouse_drag"
                                    startX, startY = object.data.eventBuffer.arg2, object.data.eventBuffer.arg3
                                    newX, newY = arg2, arg3

                                    object.data.eventHandlers.onDrag object, arg1, startX, startY, newX, newY
                        when "mouse_scroll"
                            if object.data.eventHandlers.onScroll and arg2 >= x1 and arg3 >= y1 and arg2 <= x2 and arg3 <= y2
                                object.data.hasFocus = true
                                object.data.eventHandlers.onFocusGained object
                                object.data.eventHandlers.onScroll object, arg1
                            else
                                object.data.hasFocus = false
                                object.data.eventHandlers.onFocusLost object
                        when "monitor_touch"
                            if object.data.eventHandlers.onMonitorTouch and arg2 >= x1 and arg3 >= y1 and arg2 <= x2 and arg3 <= y2
                                object.data.hasFocus = true
                                object.data.eventHandlers.onFocusGained object
                                object.data.eventHandlers.onMonitorTouch object, arg1
                            else
                                object.data.hasFocus = false
                                object.data.eventHandlers.onFocusLost object
                
                object.data.eventBuffer = {event: event, arg1: arg1, arg2: arg2, arg3: arg3}
                
                for k, v in ipairs @data.objects
                    if not v\type("FRAME")
                        x1, y1 = @data.xPos + v.data.xPos - 1, @data.yPos + v.data.yPos - 1
                        x2, y2 = x1 + v.data.width - 1, y1 + v.data.height - 1
                        
                        if v.data.width <= 0 then x2 = x1 + v\autoWidth! - 1
                        if v.data.height <= 0 then y2 = y1 + v\autoHeight! - 1
                        
                        callEventHandler v, x1, x2, y1, y2
                
                x1, y1 = @data.xPos, @data.yPos
                x2, y2 = x1 + @data.width - 1, y1 + @data.height - 1
                callEventHandler self, x1, x2, y1, y2
    
    draw: =>
        if @data.isVisible
            fXPos, fYPos, fWidth, fHeight = @data.xPos, @data.yPos, @data.width, @data.height
            
            if @data.colour.background and @data.colour.background > 0
                fill fXPos, fXPos + fWidth - 1, fYPos, fYPos + fHeight - 1, @data.colour.background
            
            for _, v in ipairs @data.objects
                if v.data.isVisible
                    if v.data.customRenderer
                        v.data.customRenderer v
                    else
                        width, height = nil, nil
                        if v.data.height > 0 and v.data.width > 0
                            width, height = v.data.width, v.data.height
                        elseif v.data.width > 0
                            width, height = v.data.width, v\autoHeight!
                        elseif v.data.height > 0
                            width, height = v\autoWidth!, v.data.height
                        else
                            width, height = v\autoWidth!, v\autoHeight!
                        
                        if width > 0 and height > 0
                            x1, y1 = v.data.xPos + fXPos - 1, v.data.yPos + fYPos - 1
                            
                            if v.data.colour.background and v.data.colour.background > 0
                                fill x1, x1 + width - 1, y1, y1 + height - 1, v.data.colour.background
                            
                            if v.data.text
                                for k, t in ipairs v.data.text
                                    if k <= height
                                        if v.data.colour.text and v.data.colour.text > 0
                                            write t\sub(1, width), x1, y1 + k - 1, v.data.colour.text
                                        else
                                            write t\sub(1, width), x1, y1 + k - 1
                                    else
                                        break
    
    removeEventListener: =>
        @data.eventListener = false

-- Global Object Creation Functions

export newButton = ->
    return Button!

export newLabel = ->
    return Label!

export newImage = ->
    return Image!

export newFrame = ->
    return Frame!

