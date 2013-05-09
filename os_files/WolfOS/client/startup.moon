WUI = os.getApi "WUI"

frame = WUI.newFrame!
image = WUI.newImage!
label = WUI.newLabel!

image\setVisible true
image\setPosition 1, 1 
image\setImage "rom/"..os.getSystemDir("client").."logo.nfp"

text = "WolfOS "..os.getVersion!.." - wolfos.co.uk"
w = term.getSize!

label\setVisible true
label\setPosition w/2 - #text/2 + 1, 17
label\setColour "text", "lightGrey"
label\setColour "background", "grey"
label\setText {text}

frame\setVisible true
frame\setColour "background", "grey"
frame\add image
frame\add label
frame\draw!

sleep 3
