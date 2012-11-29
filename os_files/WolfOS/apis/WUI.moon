-- WolfOS User Interface Library

export colourScheme = {}

if term.isColour()
    colourScheme =
        cursor: colours.white
        screen: {
            background: colours.lightGrey
            text: colours.grey
        }
        statusbar: {
            background: colours.grey
            text: colours.white
        }
        label: {
            background: colours.lightGrey
            text: colours.grey
        }
        button: {
            background: colours.lightGrey
            text: colours.grey
            focus: {
                background: colours.grey
                text: colours.lightGrey
            }
        }
        textField: {
            background: colours.grey
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
            background: colours.white
            text: colours.black
        }

export write = (t = "", x = 1, y = 1, ct, cb) ->
    term.setCursorPos x, y
    if ct then term.setTextColour ct
    if cb then term.setBackgroundColour cb
    term.write t

export clear = (cb) ->
    if cb then term.setBackgroundColour cb
    term.clear!
    term.setCursorPos 1, 1

export printToMonitor = (t) -> -- DEBUGGING FUNCTION ONLY!
    mon = peripheral.wrap("left")
    mon.write t
    _, my = mon.getCursorPos!
    _, mh = mon.getSize!
    if my == mh
        mon.scroll 1
        mon.setCursorPos 1, my
    else
        mon.setCursorPos 1, my + 1

export loadGraphic = (path) ->
    colours = {["0"]: colours.white, ["1"]: colours.orange, ["2"]: colours.magenta, ["3"]: colours.lightBlue, ["4"]: colours.yellow,
        ["5"]: colours.lime, ["6"]: colours.pink, ["7"]: colours.grey, ["8"]: colours.lightGrey, ["9"]: colours.cyan,
        a: colours.purple, b: colours.blue, c: colours.brown, d: colours.green, e: colours.red, f: colours.black}
    raw = WDM.readToTable path
    pixels = {}
    for k, v in ipairs raw
        pixels[k] = {}
        for n = 1, #v
            char = v\sub n, n
            if char != " "
                table.insert pixels[k], colours[char]
            else
                table.insert pixels[k], "alpha_channel"
    return pixels

-- Basic Functions

cursorX, cursorY = 1, 1
cursorState = -1

export getCursorPos = ->
    return cursorX, cursorY

export setCursorPos = (x, y) ->
    if type(x) == "number" and type(y) == "number"
        term.setCursorPos x, y
        cursorX, cursorY = x, y

export getCursorState = ->
    return cursorState

export setCursorState = (n) ->
    if type(n) == "number" and (n > -2 and n < 2)
        cursorState = n

export getScreenWidth = ->
    w = term.getSize!
    return w

export getScreenHeight = ->
    _, h = term.getSize!
    return h
