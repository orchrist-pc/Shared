;Originally created by @a2tc
;Updated and modified for The Final Shape by @orchrist
;
;OFFSETS
;   Resolution      -   1920 x 1080
;   Ratio           -   16 x 9
;   Starting x,y    -   145,340
;   Starting Offset -   .0495, .3148
;   Pixel Offset    -   95
;   x,y Mod Offset  -   .0495, .0875
;
;   Resolution      -   3440 x 1440
;   Ratio           -   43 x 18
;   Starting x,y    -   635,450
;   Starting Offset -   .1845, .3125
;   Pixel    Offset -   125
;   x,y Mod Offset  -   .0363, .0875
;
;   Resolution      -   5120 x 1440
;   Ratio           -   32 x 9
;   Starting x,y    -   1470,450
;   Starting Offset -   .2781, .3125
;   Pixel Offset    -   125
;   x,y Mod Offset  -   .0244, .0875
;
;   Resolution      -   3840 x 1600
;   Ratio           -   24 x 10
;   Starting x,y    -   700,500
;   Starting Offset -   .1823, .3125
;   Pixel Offset    -   129
;   x,y Mod Offset  -   .0336, .0806


;TO DO
;Need Offsets for 16/10
;
;INITIALIZATION AND GLOBAL VARIABLES

SetMouseDelay, 0
SetKeyDelay, 0
Global lo_logging = False
Global lo_logfile := a_desktop . "\D2PathfinderMacro.log"

;Grabs your current D2 Keybinds
lo_keybinds := get_lo_d2_keybinds(["ui_open_start_menu_alternative"])
if !lo_keybinds
{
    MsgBox, Could not find the cvars.xml file
    ExitApp
}
for lo_key, value in lo_keybinds 
{
    if (value == "" || value == "unused") {
        MsgBox, % "The keybind for 'Character' is not set or is an unknown key."
        ExitApp
    }
}

;Inventory Keybind
global INVENTORY := lo_keybinds["ui_open_start_menu_alternative"]

;Set Screen resolution offsets - Simple math for this is Pixel number divided by Screenwidth or Height
;  xmod / ymod = the distance between loadouts
;  xstart / ystart = the first loadout positiop
;  For 1920 x 1080p the first loadout is at x = 145
;  To get the starting offset value of x it's 145 divided by 1920, Resolves to .075
if ((A_ScreenWidth/A_ScreenHeight) == (43/18)) {
    global xmod := .0363
    global ymod := .0875
    global xstart := .1845
    global ystart := .3125
    if(lo_logging == True)
        FileAppend, INITIALIZING`nResolution Ratio - 43/18`n, %lo_logfile%
}

if ((A_ScreenWidth/A_ScreenHeight) == (16/9)) {
    global xmod := .0495
    global ymod := .0875
    global xstart := .0755
    global ystart := .3148
    if(lo_logging == True)
        FileAppend, INITIALIZING`nResolution Ratio - 16 9`n, %lo_logfile%
}

if ((A_ScreenWidth/A_ScreenHeight) == (32/9)) {
    global xmod := .0244
    global ymod := .0875
    global xstart := .2781
    global ystart := .3125
    if(lo_logging == True)
        FileAppend, INITIALIZING`nResolution Ratio - 32 9`n, %lo_logfile%
}

if ((A_ScreenWidth/A_ScreenHeight) == (24/10)) {
    global xmod := .0336
    global ymod := .0806
    global xstart := .1823
    global ystart := .3125
    if(lo_logging == True)
        FileAppend, INITIALIZING`nResolution Ratio - 32 9`n, %lo_logfile%
} 

;Error if screen ratio is not currently supported
if ((A_ScreenWidth/A_ScreenHeight) != (16/9) && (A_ScreenWidth/A_ScreenHeight) != (43/18) && (A_ScreenWidth/A_ScreenHeight) != (32/9) && (A_ScreenWidth/A_ScreenHeight) != (24/10)){
    MsgBox, % "Your Screen Resolution is not currently configured for this script."
    ;ExitApp
}

;Setup for hotkey bindings
Loop, 12 {
    LO%A_Index% := Func("selectloadout").bind(A_Index)
}

;Hotkeys are currently set to Control + key
;  Modifier values for Hotkeys can be found here: https://www.autohotkey.com/docs/v1/Hotkeys.htm
;  Ctrl: ^ | Alt: ! | Shift: +
hotkey, ifwinactive, ahk_exe destiny2.exe
hotkey, !Numpad1, % LO1
hotkey, !Numpad2, % LO2
hotkey, !Numpad3, % LO3
hotkey, !Numpad4, % LO4
hotkey, !Numpad5, % LO5
hotkey, !Numpad6, % LO6
hotkey, !Numpad7, % LO7
hotkey, !Numpad8, % LO8
hotkey, !Numpad9, % LO9
hotkey, !Numpad0, % LO10
hotkey, !NumpadSub, % LO11
hotkey, !NumpadMult, % LO12

selectloadout(loadoutnum)
{
    Send, {%INVENTORY%}
    sleep, 200
    ; this will stop the script if it's running longer than 3 secondsa
    SetTimer, lo_time_out, 3000

    ; Reference Pixel, currently set to above the topleft loadout offset by the ymod value from above
    xref := (A_ScreenWidth * xstart)
    yref := (A_ScreenHeight * (ystart - ymod))
    PixelGetColor, refcolor, xref, yref
    PixelGetColor, color, xref, yref
    rcolor := (refcolor & 0x0F0F0F0)
    ccolor := (color & 0x0F0F0F0)
    ; not entirely sure what & 0x0F0F0F0 does for certain but it was making the color checks a lot more consistent. the exact BGR values output by PixelGetColor were sometimes slightly different depending on equipped subclass
    
    if(lo_logging == True)
        FileAppend, START LOADOUT - Ref Pixel: %xref% %yref% || Ref Color: %refcolor% %rcolor% || Current Color %color% %ccolor%`n, %lo_logfile%

    ; Loops until the loadout menu screen is detected and then breaks out of the loop
    loop,
    {
        Sleep, 200
        Send, {Left}
        loadouts_loaded := 0

        ; loop is set to 20 to have a consistent application of the loadouts
        loop, 40
        {
            PixelGetColor, color, xref, yref
            rcolor := (refcolor & 0x0F0F0F0)
            ccolor := (color & 0x0F0F0F0)
            ; 2101264 is the color BGR & 0x0F0F0F0 that was consistent on the loadout screen
            if (((color & 0x0F0F0F0) == 2101264) || ((color & 0x0F0F0F0) == 3153952) || ((color & 0x0F0F0F0) == 4206640))
                loadouts_loaded += 1
        }
        if (loadouts_loaded >= 39)
        {
            SetTimer, lo_time_out, Off
            break
        }
        if(lo_logging == True)
            FileAppend, Ref Color: %refcolor% %rcolor% || Current Color %color% %ccolor%`n, %lo_logfile%
    }

    ; setting the clicking location here
    if (Mod(loadoutnum, 2) == 0)
        x := Round((A_ScreenWidth*(xstart+xmod)), 0)
    Else
        x := Round((A_ScreenWidth*xstart), 0)

    y := Round(A_ScreenHeight*((Ceil((loadoutnum)/2)*ymod)+(ystart-ymod)), 0)

    if(lo_logging == True)
        FileAppend, Selected Loadout: %loadoutnum% || Clicked Pixel: %x% || %y%`n, %lo_logfile%
    click, % x " " y " " 0
    Sleep, 60
    click, % x " " y
    click, % A_ScreenWidth/2 " " A_ScreenHeight/2 " " 0
    Sleep, 10
    Send, {%INVENTORY%}
    return
}

lo_time_out(){
    Reload
}

; DO NOT TOUCH THIS
;  loads in your current keybind cvar settings and parses with regex. @a2tc did this and I do not know regex well enough to fuck with it.
get_lo_d2_keybinds(k) 
{
    FileRead, f, % A_AppData "\Bungie\DestinyPC\prefs\cvars.xml"
    if ErrorLevel 
        return False
    b := {}, t := {"shift": "LShift", "control": "LCtrl", "alt": "LAlt", "menu": "AppsKey", "insert": "Ins", "delete": "Del", "pageup": "PgUp", "pagedown": "PgDn", "keypad`/": "NumpadDiv", "keypad`*": "NumpadMult", "keypad`-": "NumpadSub", "keypad`+": "NumpadAdd", "keypadenter": "NumpadEnter", "leftmousebutton": "LButton", "middlemousebutton": "MButton", "rightmousebutton": "RButton", "extramousebutton1": "XButton1", "extramousebutton2": "XButton2", "mousewheelup": "WheelUp", "mousewheeldown": "WheelDown", "escape": "Esc"}
    for _, n in k 
        RegExMatch(f, "<cvar\s+name=""`" n `"""\s+value=""([^""]+)""", m) ? b[n] := t.HasKey(k2 := StrReplace((k1 := StrSplit(m1, "!")[1]) != "unused" ? k1 : k1[2], " ", "")) ? t[k2] : k2 : b[n] := "unused"
    return b
}