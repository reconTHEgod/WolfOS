-- WolfOS First-time Setup

setup_loop = true

w = WUI.getScreenWidth!

setup_frame = WUI.frame.Frame "setup_frame"
setup_welcome = WUI.objects.Label "setup_welcome", w
setup_label = WUI.objects.Label "setup_label", w
setup_create_label = WUI.objects.Label "setup_create_label", w
setup_username_prompt = WUI.objects.Label "setup_username_prompt", 16
setup_username = WUI.objects.TextField "setup_username", 16
setup_password_prompt = WUI.objects.Label "setup_password_prompt", 16
setup_password = WUI.objects.PasswordField "setup_password", 16
setup_status = WUI.objects.Label "setup_status", w
setup_cancel = WUI.objects.Button "setup_cancel", 8
setup_create = WUI.objects.Button "setup_create", 8

create = =>
    if #setup_username\getText! > 7 and #setup_password\getText! > 7
        if not string.find(setup_username\getText!, "[^%w]") and not string.find(setup_password\getText!, "[^%w]")
            if not WAU.exists setup_username\getText!, hash.sha256 setup_password\getText!
                setup_status\setText ""
                setup_loop = false
            else
                setup_status\setText "That username is already in use!"
        else
            setup_status\setText "Can only contain alphanumeric characters!"
    else
        setup_status\setText "Must be at least 8 characters long!"

setup_welcome\setText "Welcome to WolfOS "..os.getVersion!.."!"
setup_welcome\setTextAlign "center"

setup_label\setText "Create an admin account below:"
setup_label\setTextAlign "center"

setup_username_prompt\setText "Username:"
setup_username\setActionListener create

setup_create_label\setTextAlign "center"

setup_password_prompt\setText "Password:"
setup_password\setActionListener create

setup_status\setTextAlign "center"
if term.isColour!
    setup_status\setTextColour colours.red

setup_cancel\setText "Cancel"
setup_cancel\setActionListener -> os.shutdown!

setup_create\setText "Create"
setup_create\setActionListener create

setup_frame\setStatusBar _STATUSBAR

h = WUI.getScreenHeight!
ch = math.ceil h / 2
cw = math.ceil (w / 2)
_cw = cw - 7
setup_frame\add setup_welcome, 1, 3
setup_frame\add setup_label, 1, 5
setup_frame\add setup_username_prompt, _cw, ch - 1
setup_frame\add setup_username, _cw, ch
setup_frame\add setup_create_label, 1, ch + 1
setup_frame\add setup_password_prompt, _cw, ch + 2
setup_frame\add setup_password, _cw, ch + 3
setup_frame\add setup_status, 1, ch + 5
setup_frame\add setup_cancel, cw - 8, h - 2
setup_frame\add setup_create, cw + 1, h - 2

while setup_loop == true
    setup_frame\waitForEvent!

setup_frame\remove "setup_username_prompt"
setup_frame\remove "setup_username"
setup_frame\remove "setup_password_prompt"
setup_frame\remove "setup_password"
setup_frame\remove "setup_status"
setup_frame\remove "setup_cancel"
setup_frame\remove "setup_create"

setup_create_label\setText "Creating account..."
setup_frame\redraw!

if not WDM.exists os.getSystemDir("data").."users.dat"
    WDM.data.writeData os.getSystemDir("data").."users.dat", {}
if not fs.isDir os.getSystemDir "users"
    fs.makeDir os.getSystemDir "users"

WAU.createUser setup_username\getText!, hash.sha256(setup_password\getText!), "admin"
setup_create_label\setText "Admin account created succesfully!"
setup_frame\redraw!
sleep 1
