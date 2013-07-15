Interface = os.getApi "Interface"

frame = Interface.newFrame!
image = Interface.newImage!
label = Interface.newLabel!

image\setVisible true
image\setPosition 1, 1 
image\setImage Interface.getFileInTheme "image.splashscreen"

w = term.getSize!

labelText = "WolfOS "..os.getVersion!.." - wolfos.co.uk"
label\setVisible true
label\setSize w
label\setPosition 1, 16
label\setText {string.rep(" ", w/2 - #labelText/2)..labelText}

frame\setVisible true
frame\add image
frame\add label
frame\draw!

sleep 2

path = os.getSystemDir("client").."login.lua"
if fs.exists "rom/"..path
    os.run {}, "rom/"..path
elseif fs.exists path
    os.run {}, path
else
    error "No login.lua file found!"
