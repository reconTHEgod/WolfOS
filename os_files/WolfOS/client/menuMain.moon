-- WolfOS Main Menu

menu_loop = true
w = WUI.getScreenWidth!

menu_frame = WUI.frame.Frame "menu_frame"
menu_welcome = WUI.objects.Label "menu_welcome", w
menu_progs = WUI.objects.Button "menu_progs", 10
menu_utils = WUI.objects.Button "menu_utils", 11
menu_controlPanel = WUI.objects.Button "menu_controlPanel", 15
menu_logout = WUI.objects.Button "menu_logout", 8
menu_reboot = WUI.objects.Button "menu_reboot", 8
menu_shutdown = WUI.objects.Button "menu_shutdown", 10

menu_welcome\setText "Welcome "..WDM.data.readTempData("current_name").."!"
menu_welcome\setTextAlign "center"

menu_progs\setText "Programs"
menu_progs\setActionListener -> 

menu_utils\setText "Utilities"
menu_utils\setActionListener -> 

menu_controlPanel\setText "Control Panel"
menu_controlPanel\setActionListener -> os.run {_STATUSBAR: _STATUSBAR}, ""

menu_logout\setText "Logout"
menu_logout\setActionListener ->
    _STATUSBAR\setUserText ""
    os.run {_STATUSBAR: _STATUSBAR}, os.getSystemDir("client").."startup.lua"

menu_reboot\setText "Reboot"
menu_reboot\setActionListener -> os.reboot!

menu_shutdown\setText "Shutdown"
menu_shutdown\setActionListener -> os.shutdown!

menu_frame\setStatusBar _STATUSBAR

h = WUI.getScreenHeight!
menu_frame\add menu_welcome, 1, 3
menu_frame\add menu_progs, 1, h - 4
menu_frame\add menu_utils, 1, h - 3
menu_frame\add menu_controlPanel, 1, h - 1
menu_frame\add menu_logout, w - 7, h - 4
menu_frame\add menu_reboot, w - 7, h - 2
menu_frame\add menu_shutdown, w - 9, h - 1

while menu_loop == true
    menu_frame\waitForEvent!
