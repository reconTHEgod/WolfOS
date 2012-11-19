-- WolfOS User Interface Library

colourScheme = {}

if term.isColour()
    colourScheme =
        cursor: colours.white
        screen: {
            background: colours.blue
            text: colours.white
        }
        statusbar: {
            background: colours.white
            text: colours.blue
        }
        label: {
            background: colours.blue
            text: colours.white
        }
        button: {
            background: colours.blue
            text: colours.white
            focus: {
                background: colours.white
                text: colours.blue
            }
        }
        textField: {
            background: colours.blue
            text: colours.white
        }
else
    colourScheme =
        cursor: colours.white
        screen: {
            background: colours.black
            text: colours.white
        }
        statusbar: {
            background: colours.white
            text: colours.black
        }
        label: {
            background: colours.black
            text: colours.white
        }
        button: {
            background: colours.black
            text: colours.white
            focus: {
                background: colours.white
                text: colours.black
            }
        }
        textField: {
            background: colours.black
            text: colours.white
        }

write = (t = "", x = 1, y = 1, ct, cb) ->
    term.setCursorPos x, y
    if ct then term.setTextColour ct
    if cb then term.setBackgroundColour cb
    term.write t

clear = (cb) ->
    if cb then term.setBackgroundColour cb
    term.clear!
    term.setCursorPos 1, 1

printToMonitor = (t) -> -- DEBUGGING FUNCTION ONLY!
    mon = peripheral.wrap("left")
    mon.write t
    _, my = mon.getCursorPos!
    _, mh = mon.getSize!
    if my == mh
        mon.scroll 1
        mon.setCursorPos 1, my
    else
        mon.setCursorPos 1, my + 1

-- Basic Functions

cursorX, cursorY = 1, 1
cursorState = -1

export getCursorPos = ->
    cursorX, cursorY

export setCursorPos = (x, y) ->
    if type(x) == "number" and type(y) == "number"
        term.setCursorPos x, y
        cursorX, cursorY = x, y

export getCursorState = ->
    cursorState

export setCursorState = (n) ->
    if type(n) == "number" and (n > -2 and n < 2)
        cursorState = n

export getScreenWidth = ->
    w = term.getSize!
    w

export getScreenHeight = ->
    _, h = term.getSize!
    h
