-- WolfOS User Interface Library
-- Frame Module

export class Frame
    new: (frameID) =>
        @name = frameID
        @type = "frame"
        @objects = {}
        @background_colour = WUI.colourScheme.screen.background
    
    setStatusBar: (statusbar) =>
        --if statusbar["type"] == "status_bar"
        @status_bar = statusbar
    
    setBackgroundColour: (c) =>
        if type(c) == "number"
            @background_colour = c
        elseif colours[c]
            @background_colour = colours[c]
    
    add: (object, x = 1, y = 1, layer = 0) =>
        object.x = x
        object.y = y
        
        if layer > 0
            table.insert @objects, layer, object
        else
            table.insert @objects, object
    
    remove: (objectID) =>
        for k, v in ipairs @objects
            if v.name == objectID
                table.remove @objects, k
                break
    
    redraw: =>
        term.setCursorBlink false
        WUI.clear @background_colour
        
        if @status_bar
            @status_bar\redraw!
        
        for k, v in ipairs @objects
            term.setBackgroundColour @background_colour
            v\redraw!
    
    waitForEvent: =>
        currentObject = nil
        n = @current_object or 0
        
        next = ->
            for k = n + 1, #@objects, 1
                v = @objects[k]
                if v\getEnabled!
                    if currentObject then currentObject\setFocus false
                    currentObject = v
                    currentObject\setFocus true
                    n = k
                    @current_object = n
                    return true
            false
        
        prev = ->
            for k = n - 1, 1, -1
                v = @objects[k]
                if v\getEnabled!
                    if currentObject then currentObject\setFocus false
                    currentObject = v
                    currentObject\setFocus true
                    n = k
                    @current_object = n
                    return true
            false
        
        mouseoverObjectPos = (x, y) ->
            for k, v in ipairs @objects
                if v\getEnabled!
                    if (x >= v.x and x <= (v.x + (v.width - 1))) and (y >= v.y and y <= (v.y + (v.height - 1)))
                        return k, v
        
        currentObject = @objects[n]
        if not currentObject then next!
        
        @redraw!
            
        if currentObject.object_type == "text_field" or currentObject.object_type == "password_field"
            term.setTextColour currentObject.colours.text
            term.setCursorPos currentObject.cursorX, currentObject.cursorY
            term.setCursorBlink true
        else
            term.setCursorBlink false
            
        event, p1, p2, p3, p4, p5 = os.pullEvent!
            
        switch event -- Allow for global event handling before object specific event handling
          when "key"
                switch p1
                  when keys.leftCtrl
                        if not next!
                            canMove = true
                            while canMove do canMove = prev!
                  when 157 -- keys.rightCtrl doesn't work on my keyboard...?
                        if not prev!
                            canMove = true
                            while canMove do canMove = next!
                  --when keys.insert
                        --if getCursorState! == 0
                            --setCursorState 1
                        --else
                            --setCursorState 0
        

            
          when "mouse_click"
                _n, object = mouseoverObjectPos p2, p3
                if object
                    if currentObject then currentObject\setFocus false
                    currentObject = object
                    currentObject\setFocus true
                    n = _n
                    @current_object = n
                    
                    @redraw!
                    sleep 0.02
        
        currentObject\eventHandler event, p1, p2, p3, p4, p5

export class StatusBar
    new: (objectID) =>
        @name = objectID
        @type = "status_bar"
        @width = WUI.getScreenWidth!
        @height = 1
        @text = 
            clock: "00:00 AM"
            user: ""
            menu: {}
        @cursor_pos = 0
        @colours = 
            text: WUI.colourScheme.statusbar.text
            background: WUI.colourScheme.statusbar.background
        @clock_twentyfour = false
    
    setUserText: (t) =>
        if type(t) == "string"
            @text.user = t\sub 1, 16
            
    runClock: =>
        time = nil
        while true
            _time = textutils.formatTime os.time!, @clock_twentyfour
            if _time != time
                time = _time
                @text.clock = time
                @redraw!
            sleep 0.1
    
    redraw: =>
        WUI.write string.rep(" ", @width), 1, 1, @colours.text, @colours.background
        
        -- TODO: Menu headers printed here
        
        s = @text.user
        if #@text.user > 0
            s ..= " - "..@text.clock
        else
            s = @text.clock
        x = @width - #s + 1
        WUI.write s, x, 1, @colours.text, @colours.background
