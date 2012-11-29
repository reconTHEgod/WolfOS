-- WolfOS Startup

if #WAU.getUsers! < 1
   os.run {_STATUSBAR: _STATUSBAR}, os.getSystemDir("client").."setup.lua"

startup_loop = true
user = nil

w = WUI.getScreenWidth!

startup_frame = WUI.frame.Frame "startup_frame"
startup_version = WUI.objects.Label "startup_version", w
startup_username_prompt = WUI.objects.Label "startup_username_prompt", 16
startup_username = WUI.objects.TextField "startup_username", 16
startup_password_prompt = WUI.objects.Label "startup_password_prompt", 16
startup_password = WUI.objects.PasswordField "startup_password", 16
startup_login_label = WUI.objects.Label "startup_login_label", w
startup_status = WUI.objects.Label "startup_status", w
startup_login = WUI.objects.Button "startup_login", 7
startup_reboot = WUI.objects.Button "startup_reboot", 8
startup_shutdown = WUI.objects.Button "startup_shutdown", 10

login = =>
    ok, p1 = WAU.checkLogin startup_username\getText!, hash.sha256 startup_password\getText!
    if ok
        startup_status\setText ""
        startup_loop = false
        user = p1
    else
        startup_status\setText p1

startup_version\setText "WolfOS "..os.getVersion!
startup_version\setTextAlign "center"

startup_username_prompt\setText "Username:"
startup_username\setActionListener login

startup_password_prompt\setText "Password:"
startup_password\setActionListener login

startup_login_label\setTextAlign "center"
startup_login\setText "Login"
startup_login\setActionListener login

startup_status\setTextAlign "center"
if term.isColour!
    startup_status\setTextColour colours.red

startup_reboot\setText "Reboot"
startup_reboot\setActionListener -> os.reboot!

startup_shutdown\setText "Shutdown"
startup_shutdown\setActionListener -> os.shutdown!

startup_frame\setStatusBar _STATUSBAR

h = WUI.getScreenHeight!
ch = math.ceil h / 2
cw = math.ceil (w / 2) - 7
startup_frame\add startup_version, 1, 3
startup_frame\add startup_username_prompt, cw, ch - 3
startup_frame\add startup_username, cw, ch - 2
startup_frame\add startup_login_label, 1, ch - 1
startup_frame\add startup_password_prompt, cw, ch
startup_frame\add startup_password, cw, ch + 1
startup_frame\add startup_status, 1, ch + 3
startup_frame\add startup_login, 1, h - 5
startup_frame\add startup_reboot, 1, h - 3
startup_frame\add startup_shutdown, 1, h - 1

while startup_loop == true
    startup_frame\waitForEvent!

startup_frame\remove "startup_username_prompt"
startup_frame\remove "startup_username"
startup_frame\remove "startup_password_prompt"
startup_frame\remove "startup_password"
startup_frame\remove "startup_status"

startup_login_label\setText "Logging in..."
startup_frame\redraw!

WDM.data.writeTempData user.uid, "current_uid"
WDM.data.writeTempData user.name, "current_name"
WDM.data.writeTempData user.hash, "current_hash"
WDM.data.writeTempData user.type, "current_type"

os.run {}, os.getSystemDir("client").."menuMain.lua"
