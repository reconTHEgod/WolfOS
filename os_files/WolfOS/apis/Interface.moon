-- WolfOS User Interface Library

Data = os.getApi "Data"

export getLocalizedString = (key) ->
    s = Data.readTempData("localization")[Data.readClientData("current_locale")][key]
    
    if s and s != ""
        return s
    return key

export getValueInTheme = (key) ->
    s = Data.readTempData("themes")[Data.readClientData("current_theme")][key]
    
    if s and s != ""
        return s
    return Data.readTempData("themes")["Default"][key]

export getFileInTheme = (key) ->
    theme = Data.readTempData("themes")[Data.readClientData("current_theme")]
    
    if theme[key]
        return fs.combine theme.__path, theme[key]
    else
        theme = Data.readTempData("themes")["Default"]
        return fs.combine theme.__path, theme[key]

export getScreenWidth = ->
    w = term.getSize!
    return w

export getScreenHeight = ->
    _, h = term.getSize!
    return h

-----------------------------------------

Colors = require "rom.apis.colors"
PaintUtils = require "rom.apis.paintutils"

env = getfenv PaintUtils.loadImage
env.io = require "rom.apis.io"
setfenv PaintUtils.loadImage, env

checkColor = (c) ->
    if type(c) != "number"
        c = Colors[c]
    if c
        return c
    return 0

fill = (x1 = 0, x2 = 0, y1 = 0, y2 = 0, c) ->
    c = checkColor c
    for x = x1, x2
        for y = y1, y2
            if c > 0
                PaintUtils.drawPixel x, y, c

setBackgroundColor = (c) ->
    c = checkColor c
    term.setBackgroundColor c

setTextColor = (c) ->
    c = checkColor c
    term.setTextColor c

write = (t = "", x = 1, y = 1, ct, cb) ->
    term.setCursorPos x, y
    if ct then setTextColor ct
    if cb then setBackgroundColor cb
    term.write t

clear = (c) ->
    if c
        setBackgroundColor c
    else
        setBackgroundColor "black"
    term.clear!
    term.setCursorPos 1, 1

-- Parent Class

class Object
    setColor: (k, v) =>
        c = checkColor v
        @data.color[k] = c
    
    setEnabled: (b) =>
        ok, err = ftype "boolean", b
        if @data.isEnabled != nil and ok
            @data.isEnabled = b
        elseif not ok
            error err, 2
    
    setEventHandler: (f, k, j) =>
        ok, err = ftype "function, string", f, k
        if type(@data.eventHandlers[k]) == "function" and ok
            @data.eventHandlers[k] = f
        elseif type(@data.eventHandlers[k]) == "table" and ok
            @data.eventHandlers[k][j] = f
        elseif not ok
            error err, 2
        else
            error "Attempt to register invalid eventHandler", 2
    
    setPosition: (x, y) =>
        ok, err = ftype "+number, +number", x, y
        if ok    
            @data.xPos, @data.yPos = math.floor(x), math.floor(y)
        else
            error err, 2
    
    setSize: (w = 0, h = 0) =>
        ok, err = ftype "+number, +number", w, h
        if ok  
            @data.width, @data.height = math.floor(w), math.floor(h)
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
            color: {
                background: checkColor getValueInTheme "color.general.button"
                highlight: checkColor getValueInTheme "color.general.button.highlight"
                text: checkColor getValueInTheme "color.general.text"
            }
            width: 0
            height: 0
            xPos: 0
            yPos: 0
            isEnabled: true
            isVisible: false
            eventHandlers: {
                onClick: {
                    left: (x, y) =>
                    middle: (x, y) =>
                    right: (x, y) =>
                }
                onDrag: {
                    left: (startX, startY, newX, newY) =>
                    middle: (startX, startY, newX, newY) =>
                    right: (startX, startY, newX, newY) =>
                }
                onFocusGained: =>
                onFocusLost: =>
                onKeyPress: {}
                onMonitorTouch: (monitorPort, x, y) =>
            }
    
    draw: =>
        width, height = @data.width, @data.height
        if width <= 0 then width = @autoWidth!
        if height <= 0 then height = @autoHeight!
        
        if width > 0 and height > 0
            x1, y1 = @data.xPos + @data.parent.xPos - 1, @data.yPos + @data.parent.yPos - 1
            
            if @data.hasFocus and @data.color.highlight and @data.color.highlight > 0
                fill x1, x1 + width - 1, y1, y1 + height - 1, @data.color.highlight
            elseif @data.color.background and @data.color.background > 0
                fill x1, x1 + width - 1, y1, y1 + height - 1, @data.color.background
            
            if @data.text
                for k, t in ipairs @data.text
                    if k < height
                        if @data.color.text and @data.color.text > 0
                            write t\sub(1, width), x1 + 1, y1 + k, @data.color.text
                        else
                            write t\sub(1, width), x1 + 1, y1 + k
                    else
                        break
    
    autoWidth: =>
        if @data.text
            i = 0
            for k, v in ipairs @data.text
                if v and v\len! > i
                    i = v\len!
            return i + 2
    
    autoHeight: =>
        return #@data.text + 2

class Image extends Object
    new: =>
        @data =
            type: "Object.IMAGE"
            pixels: {}
            width: 0
            height: 0
            xPos: 0
            yPos: 0
            isVisible: false
    
    setImage: (path) =>
        @data.pixels = PaintUtils.loadImage path
        @data.width = @autoWidth!
        @data.height = @autoHeight!
    
    draw: =>
        width, height = @data.width, @data.height
        
        if width > 0 and height > 0
            x1, y1 = @data.xPos + @data.parent.xPos - 1, @data.yPos + @data.parent.yPos - 1
            
            for y = 1, @data.height
                for x = 1, @data.width
                    c = @data.pixels[y][x]
                    if c > 0
                        PaintUtils.drawPixel x1 + x - 1, y1 + y - 1, c
                    
                    if not @data.pixels[y][x + 1] then break
                if not @data.pixels[y + 1] then break
    
    autoWidth: =>
        if @data.pixels
            i = 0
            for k, v in ipairs @data.pixels
                if v and #v > i
                    i = #v
            return i + 2
        return 0
    
    autoHeight: =>
        if @data.pixels
            return #@data.pixels + 2
        return 0

class Label extends Object
    new: =>
        @data =
            type: "Object.LABEL"
            text: {}
            color: {
                background: checkColor getValueInTheme "color.general.title"
                text: checkColor getValueInTheme "color.general.text"
            }
            width: 0
            height: 0
            xPos: 0
            yPos: 0
            isEnabled: true
            isVisible: false
    
    draw: =>
        width, height = @data.width, @data.height
        if width <= 0 then width = @autoWidth!
        if height <= 0 then height = @autoHeight!
        
        if width > 0 and height > 0
            x1, y1 = @data.xPos + @data.parent.xPos - 1, @data.yPos + @data.parent.yPos - 1
            
            if @data.color.background and @data.color.background > 0
                fill x1, x1 + width - 1, y1, y1 + height - 1, @data.color.background
            
            if @data.text
                for k, t in ipairs @data.text
                    if k < height
                        if @data.color.text and @data.color.text > 0
                            write t\sub(1, width), x1 + 1, y1 + k, @data.color.text
                        else
                            write t\sub(1, width), x1 + 1, y1 + k
                    else
                        break
    
    autoWidth: =>
        if @data.text
            i = 0
            for k, v in ipairs @data.text
                if v and v\len! > i
                    i = v\len!
            return i + 2
        
    autoHeight: =>
        return #@data.text + 2

class TextField extends Object
    new: =>
        @data =
            type: "Object.TEXT_FIELD"
            text: {}
            input: {
                currentLine: 0
                currentPos: 0
            }
            color: {
                background: checkColor getValueInTheme "color.general.button"
                highlight: checkColor getValueInTheme "color.general.button.highlight"
                text: checkColor getValueInTheme "color.general.text"
            }
            width: 0
            height: 0
            xPos: 0
            yPos: 0
            isEnabled: true
            isVisible: false
            eventHandlers: {
                onChar: (char) =>
                    line = @data.input[@data.input.currentLine]
                    pos = @data.input.currentPos
                    if line
                        line = line\sub(1, pos - 1)..char..line\sub(pos)
                        @data.input[@data.input.currentLine] = line
                        @data.input.currentPos += 1
                    else
                        @data.input[@data.input.currentLine] = char
                        @data.input.currentPos += 1
                onClick: {
                    left: (x, y) =>
                        if @data.input[y - @data.yPos + 1]
                            @data.input.currentLine = y - @data.yPos + 1
                        if (x - @data.xPos + 1) - @data.input.currentPos > 0 and (x - @data.xPos + 1) - @data.input.currentPos <= #@data.input[@data.input.currentLine] + 1
                                @data.currentPos = (x - @data.xPos + 1) - @data.input.currentPos
                    middle: (x, y) =>
                    right: (x, y) =>
                }
                onDrag: {
                    left: (startX, startY, newX, newY) =>
                    middle: (startX, startY, newX, newY) =>
                    right: (startX, startY, newX, newY) =>
                }
                onFocusGained: =>
                    if @data.input.currentLine < 1 then @data.input.currentLine = 1
                    if @data.input.currentPos < 1 then @data.input.currentPos = 1
                    if not @data.input[@data.input.currentLine] then @data.input[@data.input.currentLine] = ""
                onFocusLost: =>
                    term.setCursorBlink false
                onKeyPress: {
                    [14]: => -- Backspace
                        line = @data.input[@data.input.currentLine]
                        pos = @data.input.currentPos
                        if line and pos > 1
                            line = line\sub(1, pos - 2)..line\sub(pos)
                            @data.input[@data.input.currentLine] = line
                            @data.input.currentPos -= 1
                    [199]: => -- Home
                        @data.input.currentPos = 1
                    [203]: => -- Left Arrow
                        if @data.input.currentPos > 1
                            @data.input.currentPos -= 1
                    [205]: => -- Right Arrow
                        line = @data.input[@data.input.currentLine]
                        if line and @data.input.currentPos <= #line
                            @data.input.currentPos += 1
                    [207]: => -- End
                        line = @data.input[@data.input.currentLine]
                        if line
                            @data.input.currentPos = #line + 1
                    [211]: => -- Delete
                        line = @data.input[@data.input.currentLine]
                        pos = @data.input.currentPos
                        if line and pos > 0
                            line = line\sub(1, pos - 1)..line\sub(pos + 1)
                            @data.input[@data.input.currentLine] = line
                }
                onMonitorTouch: (monitorPort, x, y) =>
            }
    
    draw: =>
        width, height = @data.width, @data.height
        if width <= 0 then width = @autoWidth!
        if height <= 0 then height = @autoHeight!
        
        if width > 0 and height > 0
            x1, y1 = @data.xPos + @data.parent.xPos - 1, @data.yPos + @data.parent.yPos - 1
            
            if @data.hasFocus and @data.color.highlight and @data.color.highlight > 0
                fill x1, x1 + width - 1, y1, y1 + height - 1, @data.color.highlight
            elseif @data.color.background and @data.color.background > 0
                fill x1, x1 + width - 1, y1, y1 + height - 1, @data.color.background
            
            if @data.text
                for k, t in ipairs @data.text
                    if k < height
                        text = if @data.input[k] then t..@data.input[k] else t
                        
                        if @data.color.text and @data.color.text > 0
                            write text\sub(1, width - 2), x1 + 1, y1 + k, @data.color.text
                        else
                            write text\sub(1, width - 2), x1 + 1, y1 + k
                    else
                        break
            
                if @data.hasFocus
                    term.setCursorPos @data.xPos + #@data.text[@data.input.currentLine] + @data.input.currentPos,
                        @data.yPos + @data.input.currentLine
                    
                    term.setCursorBlink true
    
    autoWidth: =>
        if @data.text
            i = 0
            for k, v in ipairs @data.text
                if v and v\len! > i
                    i = v\len!
            return i + 2
        
    autoHeight: =>
        return #@data.text + 2

-- Frame Class

class Frame extends Object
    new: =>
        @data =
            type: "Object.FRAME"
            color: {
                background: checkColor getValueInTheme "color.general.background"
            }
            width: getScreenWidth!
            height: getScreenHeight!
            xPos: 1
            yPos: 1
            objects: {}
            isEnabled: true
            isVisible: false
            eventListener: false
    
    add: (object) =>
        if object and object\type! and not object\type "Object.FRAME"
            object.data.parent = @data
            table.insert @data.objects, object
    
    addEventListener: =>
        @data.eventListener = true
        event, arg1, arg2, arg3 = nil, nil, nil, nil
        
        callEventHandler = (object, x1, x2, y1, y2, k) ->
            if object.data.eventHandlers and object.data.isEnabled and object.data.isVisible
                switch event
                    when "mouse_click"
                        if object.data.eventHandlers.onClick and arg2 >= x1 and arg3 >= y1 and arg2 <= x2 and arg3 <= y2
                            object.data.hasFocus = true
                            
                            button = if arg1 == 1 then "left" elseif arg1 == 2 then "right" elseif arg1 == 3 then "middle"
                            object.data.eventHandlers.onClick[button] object, arg2, arg3
                        else
                            object.data.hasFocus = false
                            object.data.eventHandlers.onFocusLost object
                    when "mouse_drag"
                        if object.data.eventHandlers.onDrag and object.data.hasFocus
                            if object.data.eventBuffer.event == "mouse_click" or object.data.eventBuffer.event == "mouse_drag"
                                startX, startY = object.data.eventBuffer.arg2, object.data.eventBuffer.arg3
                                newX, newY = arg2, arg3
                                
                                button = if arg1 == 1 then "left" elseif arg1 == 2 then "right" elseif arg1 == 3 then "middle"
                                object.data.eventHandlers.onDrag[button] object, startX, startY, newX, newY
                    when "mouse_scroll"
                        if object.data.eventHandlers.onScroll and arg2 >= x1 and arg3 >= y1 and arg2 <= x2 and arg3 <= y2
                            object.data.eventHandlers.onScroll object, arg1
                    when "monitor_touch"
                        if object.data.eventHandlers.onMonitorTouch and arg2 >= x1 and arg3 >= y1 and arg2 <= x2 and arg3 <= y2
                            object.data.hasFocus = true
                            object.data.eventHandlers.onMonitorTouch object, arg1
                        else
                            object.data.hasFocus = false
                            object.data.eventHandlers.onFocusLost object, arg2, arg3
                    when "key"
                        if object.data.eventHandlers.onKeyPress and object.data.eventHandlers.onKeyPress[arg1]
                            object.data.eventHandlers.onKeyPress[arg1] object
                    when "char"
                        if object.data.eventHandlers.onChar
                            object.data.eventHandlers.onChar object, arg1
            
            object.data.eventBuffer = {event: event, arg1: arg1, arg2: arg2, arg3: arg3}
        
        while @data.eventListener
            @draw!
            event, arg1, arg2, arg3 = os.pullEvent!
            
            for k, v in ipairs @data.objects
                x1, y1 = @data.xPos + v.data.xPos - 1, @data.yPos + v.data.yPos - 1
                x2, y2 = x1 + v.data.width - 1, y1 + v.data.height - 1
                
                if v.data.width <= 0 then x2 = x1 + v\autoWidth! - 1
                if v.data.height <= 0 then y2 = y1 + v\autoHeight! - 1
                
                callEventHandler v, x1, x2, y1, y2, k
            
            for k, v in ipairs @data.objects
                if v.data.hasFocus == true
                    object = table.remove @data.objects, k
                    table.insert @data.objects, object
                    break
    
    draw: =>
        if @data.isVisible
            fXPos, fYPos, fWidth, fHeight = @data.xPos, @data.yPos, @data.width, @data.height
            
            if @data.color.background and @data.color.background > 0
                fill fXPos, fXPos + fWidth - 1, fYPos, fYPos + fHeight - 1, @data.color.background
            
            for k, v in ipairs @data.objects
                if v.data.isVisible
                    v\draw!
    
    removeEventListener: =>
        @data.eventListener = false
    
    setFocusedObject: (object) =>
        for k, v in ipairs @data.objects
            if object == v
                v.data.hasFocus = true
                v.data.eventHandlers.onFocusGained object
                _object = table.remove @data.objects, k
                table.insert @data.objects, _object
                break

-- Global Object Creation Functions

export newButton = ->
    return Button!

export newImage = ->
    return Image!

export newLabel = ->
    return Label!

export newTextField = ->
    return TextField!

export newFrame = ->
    return Frame!

