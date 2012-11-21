-- WolfOS User Interface Library
-- Frame Module

frame = getfenv!

class Frame
    new: (frameID) =>
        @name = frameID
        @type = "frame"
        @objects = {}
        @background_colour = WUI.colourScheme.screen.background
    
    setBackgroundColour: (c) =>
        if type(c) == "number"
            @background_colour = c
        elseif colours[c]
            @background_colour = colours[c]
    
    add: (object, x = 1, y = 1, layer) =>
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
        WUI.clear @background_colour
        
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
        
        while true
            @redraw!
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
                      when keys.insert
                            if getCursorState! == 0
                                setCursorState 1
                            else
                                setCursorState 0
                

                                
              when "mouse_click"
                    _n, object = mouseoverObjectPos p2, p3
                    if object
                        if currentObject then currentObject\setFocus false
                        currentObject = object
                        currentObject\setFocus true
                        n = _n
                        @current_object = n
                        
                        switch p1
                          when 1 -- Left click
                                return currentObject\action_listener!
                          --when 2 -- Right click
                                
                          --when 3 -- Middle click

frame.Frame = Frame
