WUI = os.getApi "WUI"

frame = WUI.newFrame!
image = WUI.newImage!
label = WUI.newLabel!

image\setVisible true
image\setPosition 1, 1 
image\setImage WUI.getFileInTheme "splashscreen.image"

text = "WolfOS "..os.getVersion!.." - wolfos.co.uk"
w = term.getSize!

label\setVisible true
label\setPosition w/2 - #text/2 + 1, 17
label\setColor "text", "lightGray"
label\setColor "background", "gray"
label\setText {text}

frame\setVisible true
frame\setColor "background", "gray"
frame\add image
frame\add label
frame\draw!

sleep 3
