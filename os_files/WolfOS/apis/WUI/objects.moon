-- WolfOS User Interface Library
-- Objects Module

objects = getfenv!

class Object
    _init: (objectID, objectType) =>
        @name = objectID
        @type = "object"
        @object_type = objectType
        @action_listener = =>
        @is_enabled = true
        @has_focus = false
        @width = 0
        @height = 0
        @text = ""
        @text_align = "left"
        @cursor_pos = 0
        @colours = 
            text: 0
            cursor: 0
            background: 0
            focus: {
                text: 0
                cursor: 0
                background: 0
            }
    
    setActionListener: (f) =>
        if type(f) == "function"
            @action_listener = f
    
    setEnabled: (b) =>
        if type(b) == "boolean"
            @is_enabled = b
    
    setFocus: (b) =>
        if type(b) == "boolean"
            @has_focus = b
    
    setText: (t) =>
        if type(t) == "string"
            @text = t
    
    setTextAlign: (s = "left") =>
        s = string.lower s
        if s == "left" or s == "center" or s == "right"
            @text_align = s
    
    getEnabled: =>
        @is_enabled
    
    getFocus: =>
        @has_focus
    
    getText: =>
        @text
    
    getTextAlign: =>
        @text_align
    
    eventHandler: (event, p1, p2, p3, p4, p5) =>
    
    redraw: =>
        error "no redraw function exists for object type '"..@object_type.."'!"
objects.Object = Object

class Label extends Object
    new: (labelID, w = 1) =>
        @_init labelID, "label"
        @width = w
        @height = 1
        @setEnabled false
        @colours.text = WUI.colourScheme.label.text
        @colours.background = WUI.colourScheme.label.background
    
    redraw: =>
        WUI.write string.rep(" ", @width), @x, @y, @colours.text, @colours.background
        
        x, y = @x, @y
        switch @text_align
            when "center"
                x = @x + math.ceil (@width / 2) - (#@text / 2)
            when "right"
                x = (@x + @width) - #@text
        
        WUI.write @text\sub(1, @width), x, y
objects.Label = Label

class Button extends Object
    new: (buttonID, w = 1) =>
        @_init buttonID, "button"
        @width = w
        @height = 1
        @colours.text = colourScheme.button.text
        @colours.background = colourScheme.button.background
        @colours.focus.text = colourScheme.button.focus.text
        @colours.focus.background = colourScheme.button.focus.background
    
    eventHandler: (event, p1, p2, p3, p4, p5) =>
        if event == "key" and p1 == keys.enter
            printToMonitor "Selected "..currentObject.name
            return @action_listener!
    
    redraw: =>
        t = @colours.text
        b = @colours.background
        
        if @getFocus!
            t = @colours.focus.text
            b = @colours.focus.background
        
        WUI.write string.rep(" ", @width), @x, @y, t, b
        
        x, y = @x, @y
        x = @x + math.ceil (@width / 2) - (#@text / 2)
        WUI.write @text\sub(1, @width), x, y
objects.Button = Button

class TextField extends Object
    new: (textFieldID, w = 1) =>
        @_init textFieldID, "text_field"
        @width = w
        @height = 1
        @cursor_pos = 1
        @colours.text = WUI.colourScheme.textField.text
        @colours.background = WUI.colourScheme.textField.background
    
    eventHandler: (event, p1, p2, p3, p4, p5) =>
        switch event
          when "key"
                switch p1
                  when keys.home
                        @cursor_pos = 1
                  when keys["end"] -- Circumvents strangeness
                        @cursor_pos = #@text + 1
                  when keys.backspace
                        @text = @text\sub(1, @cursor_pos - 2)..@text\sub(@cursor_pos, #@text)
                        @cursor_pos -= 1
                  when keys.delete
                        @text = @text\sub(1, @cursor_pos - 1)..@text\sub(@cursor_pos + 1, #@text)
                  when keys.enter
                        return @action_listener!
          when "char"
                @text ..= p1
                @cursor_pos += 1
        
        @redraw!
    
    redraw: =>
        WUI.write string.rep(" ", @width), @x, @y, @colours.text, @colours.background
        
        x, y = @x, @y
        switch @text_align
            when "center"
                x = @x + math.ceil (@width / 2) - (#@text / 2)
            when "right"
                x = (@x + @width) - #@text
        
        WUI.write @text\sub(1, @width), x, y
objects.TextField = TextField
