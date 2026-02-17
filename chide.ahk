/*
  ____  _      _                       _
 / __ \| |    (_)                     | |
| /  \/| |__   _  _ __   _   _      __| |  ___ __   __
| |    | '_ \ | || '_ \ | | | |    / _` | / _ \\ \ / /
| \__/\| | | || || |_) || |_| | _ | (_| ||  __/ \ V /
 \____/|_| |_||_|| .__/  \__, |(_) \__,_| \___|  \_/
                 | |      __/ |
                 |_|     |___/

----------------------CHANGE LOG-----------------------
0.7.4 - Added "ms-" to the target window name default
0.7.5 - Removed auto-prefix for window targeting
1.0.2 - Recompiled AHk "2.0.19"
1.0.4 - Added MouseButton repeatition
1.0.5 - Added CAL integration
      - Added settings menu with editible hotkeys
1.0.8 - Added New icon ref
      - Added hotkey corrections
      - Added toggle functionfor state
      - Added ico toggle
      - Added logging variable values
1.0.9
- [x] adding version query
- [x] adding update downloader
- [x] adding bump-block-protector
- [x] added github releases
1.0.10-11
- [x] Tested updater
1.1.1.
- [x] Added manual update query (by clicking script name in TrayMenu)
- [x] Added example ahk_exe
- [ ] Improved auto-disable timer
*/

#include ..\chipys-ahk-library\chipys-ahk-library.ahk


#SingleInstance
Persistent
; sendmode "event"
sendmode "Input"
SetMouseDelay 25

app_version := "1.1.3", unused := "custom var"
;@Ahk2Exe-Let U_version = %A_PriorLine~U)^(.+"){1}(.+)".*$~$2%

;@Ahk2Exe-SetCopyright    Freeware written by Chipy
;@Ahk2Exe-SetCompanyName  Chipy.dev
;@Ahk2Exe-SetFileVersion  %U_version%
;@Ahk2Exe-SetName         Chipy's Human Interface Device Extension
;@Ahk2Exe-SetDescription  Chipy's collection of HID improvements and extensions
;@Ahk2Exe-SetOrigFilename chide.ahk
;@Ahk2Exe-SetMainIcon     chide.ico


;natually to hide warning for end users
/*@Ahk2Exe-Keep
#Warn All, Off
*/

global LOG_LEVEL := 0
global SCRIPT_NAME := "chide"
global CFG_PATH := SCRIPT_NAME ".cfg"
global LOG_PATH := SCRIPT_NAME ".log"
SCRIPT_LABEL := "Chipy HIDExtensions"


coded_on := "2.0.19"
if A_AhkVersion != coded_on and !A_IsCompiled
    msgbox "You are running AHK v" A_AhkVersion "`n`rThis code was writting on v" coded_on "`n`nPlease download that exact version from autohotkey.com/download/2.0/"


move_distance := 200
bump_interval := 290000
bump_duration := 2000
bump_mode := "centered"
auto_off_mins := 0
auto_off_start := 0
mmo_mode := False
log_overflow := ""


/*
=================================================================================================
CONFIG setup
=================================================================================================
*/
script_meta := MetaInfo(app_version, "chide.exe", script_label, ".\chide.ico", , cfg_path)
TraySetIcon(script_meta.custom_icon_path)

; hotkeys
global binder := ConfigManagerTool(cfg_path, "Hotkeys", , script_meta)
binder.ini("toggle_bumper", , "", "hotkey", "Hotkey to toggle the mouse bumper state", ["toggle", "*1"])
binder.ini("open_settings", , "", "hotkey", "Hotkey to open this settings menu", ["toggle", "*1"])
binder.ini("auto_click", , "", "hotkey", "Hotkey to toggle Auto-Clicking using the defined settings", ["toggle", "*1"])
binder.ini("restart_script", , "", "hotkey", "Hotkey to reload the script", ["toggle", "*1"])
binder.ini("remap_trigger", , "", "hotkey", "Hotkey to trigger remapped key", ["toggle", "*1"])

; General
global cfg := ConfigManagerTool(cfg_path, "ConfigSettings", , script_meta)
cfg.ini("target_window", , "ahk_exe ShooterGame.exe", "edit", "Name of winow/app that should receive focus for winow-specific actions.`nConsists of a PREFIX (ahk_exe, ahk_class, ahk_id) and a windowHDL`n`nUse 'ahk_exe ' and then the 'APP.exe' name for easiest user reference.")
cfg.ini("log_level", , 5, "edit", "Sets logging level, lower value = more detail. `nUsed to show/hide things like UpdateNotification(passiveNoActionNeeded) items `n(Default: 5)")
; Bump settings
cfg.ini("bump_interupt_protection", , 1, "checkbox", "Bump protection help prevent script interupting actively used mouse. (disabling this will block mouse inputs for the duration of the bump action)`n(Default:1)")
cfg.ini("bump_mode", , "relative", "edit", "Set the bumper mode. Current options:`n1 - 'Centered' where the mouse will move around from the center of the screen`n2 - 'Relative' where the mouse moves relative to it's current position `n(Default:Relative)")
cfg.ini("auto_off_mins", , 0, "edit", "New time to run for before automatically turning off?`n60 = 1 Hour`n480 = 8 Hours/workday")
cfg.ini("mmo_mode", , 0, "edit", "Toggle for MMOs to move left right with A and D when bumping (1 = on, 0 = off)`n(Default:0)")
cfg.ini("bump_distance_variance", , 50, "edit", "Distance in pixels to use as random variance range. `n(Default: 50)")
cfg.ini("bump_distance", , 500, "edit", "Distance in pixels to move the mouse when bumping it. `n(Default: 500)")
cfg.ini("bump_interval", , 290000, "edit", "Time in ms between bump checks. 60,000 = 1 minute, 300,000 = 5 minutes.`n(Default:290,000)")
cfg.ini("bump_duration", , 1000, "edit", "REPLACED (v1.1.0) by 'bump_speed'`nTime in ms to be moving the mouse. AKA duration of the bump. ")
cfg.ini("bump_input_mode", , "Event", "edit", "Set the input mode for the bump event. Interacts with bump_speed setting.`n'Event' will emulate mouse movements better. `n'Input' will be faster.`n(Default: 'Event')")
cfg.ini("bump_speed", , 15, "edit", "Speed is the movement speed of the mouse during the bump motion. Range 0-100 lower is faster `n(Default:15)")
cfg.ini("bump_notifications", , 0, "edit", "Sets the notification mode for mouse bumper:`n0 - off`n1 - Windows Toaster Notifications`n2 - Toaster + Tooltips when bumping mouse")
cfg.ini("bumper_active", , , "Checkbox", "Toggle to track the active state of the bumper")
; Remapper settings
cfg.ini("remap_key", , , "edit", "Set the input key to be played/used`n`n" HOTKEY_CHEATSHEET)
; AutoClicker
cfg.ini("auto_click_key", , "LBUTTON", "edit", "Set the input key to be repeated`n`n" HOTKEY_CHEATSHEET)
cfg.ini("auto_click_interval", , 1000, "edit", "Set the interval in ms between each auto-click repedition")
cfg.ini("auto_click_active", , , "Checkbox", "Toggle to track the active state of the auto input repeating AutoClick")

; internal state trackers
global internal_state := ConfigManagerTool(cfg_path, "state", , script_meta)
internal_state.ini("tray_icon", , "chide_active.ico", "edit", "", ["toggle", "*1"])

version_request_variable := ComObject("Msxml2.ServerXMLHTTP")
load_settings()
Tray_setup()

; testing update pull
global update_handler := UpdateHandler(, script_meta.app_version, script_meta.file_name, script_meta.display_name, "chipys-human-interface-device-extension")


notify_user(build_tray_string(cfg.c["bumper_active"].value, cfg.c["auto_off_mins"].value), " v" app_version " Ready!")
; TrayTip(build_tray_string(cfg.c["bumper_active"].value, cfg.c["auto_off_mins"].value), script_label " v" app_version " Ready!", "Mute")
; fetch_latest_version_and_prompt("https://chipy.dev/res/Chipys_Mouse_Bumper.exe_version.txt")

return


/*
=================================================================================================
END OF AUTO EXEC
=================================================================================================
*/
/*
=================================================================================================
FUNCTIONS
=================================================================================================
*/

DisplayCurrentTimePlus(minutes, use_military_time := False, time_only := False, title := "Until: ") {
    if minutes < 1
        return ""

    ; Get current system time in YYYYMMDDHH24MISS format
    currentTime := A_Now

    ; Convert minutes to seconds
    secondsToAdd := minutes * 60

    ; Add seconds to current time
    futureTime := DateAdd(currentTime, secondsToAdd, "Seconds")

    ; Format as HH:MM
    if use_military_time
        formattedTime := FormatTime(futureTime, "HH:mm")
    else
        formattedTime := FormatTime(futureTime, "hh:mm tt")

    ; Allow time only output
    if time_only
        return formattedTime
    return " (" title "" formattedTime ")"
}


; Build the string for TrayTip (toaster) notificaiton of current state on reboot
build_tray_string(bumper_state, auto_off_mins) {
    tip_string := bumper_state ? "Mode: Active" : "Mode: Inactive"
    if auto_off_mins
        tip_string .= DisplayCurrentTimePlus(auto_off_mins)
    return tip_string
}


open_settings() {
    cfg.gui_open()
}

open_bindings() {
    binder.gui_open()
    binder.unbind_all()
    binder.bind_all_keys()
}

open_dev() {
    ; toggle_tray_icon()
    ; internal_state.gui_open()

    ; test write perms
    if (MsgBox("Will now attempt to write to file:: " LOG_PATH, "TEST?", "icon? yn") = "yes") {

        FileAppend(FormatTime(A_Now, "yyyyMMdd HH:mm:ss") "|: DEV TEST STRING`n", LOG_PATH)
        MsgBox "If you've seen no errors it likely worked, will attempt to open logs now"
        run(LOG_PATH)
    }
}

auto_click() {
    ; global
    cfg.c["auto_click_active"].value := !cfg.c["auto_click_active"].value
    cfg.c["auto_click_active"]._save()
    tooltip_timeout(3000)
    if (cfg.c["auto_click_active"].value) {
        ToolTip "Repeating [" cfg.c["auto_click_key"].value "] every (" cfg.c["auto_click_interval"].value ")ms"
        ; Start auto repeat timer loop
        SetTimer(auto_click_individual_action, cfg.c["auto_click_interval"].value * -1)
    } else {
        ToolTip "STOPPING..."
        SetTimer(auto_click_individual_action, 0)
    }

}
; # Take the most basic single action for AutoRepeating.
; Expected to be used as a callback in a timer
auto_click_individual_action() {
    ; repeat the basic action
    send("{" cfg.c["auto_click_key"].value " down}")
    sleep 5
    send("{" cfg.c["auto_click_key"].value " up}")

    ; now continue action IF we are still toggled active
    ; - this self calling allows for dynamic changes to key, interval and HALTING
    if cfg.c["auto_click_active"].value {
        SetTimer(auto_click_individual_action, cfg.c["auto_click_interval"].value * -1)
    }
}

restart_script() {
    reload
}

toggle_bumper()
{
    activate_bumper()
}

toggle_tray_icon(toggle_state := -1) {
    global internal_state, script_meta
    ; Set defaults if we arn't being directed to set a given state
    if (toggle_state == -1) {
        toggle_state := !internal_state.c["tray_icon"].toggle
    }

    ; tooltip internal_state.c["tray_icon"].ToString()
    ; MsgBox internal_state.c["tray_icon"].ToString() "`nstate == " internal_state.c["tray_icon"].toggle

    try {
        ; execute toggle
        if (toggle_state and internal_state.c.Has("tray_icon")) {
            ; MsgBox "Setting to :: " internal_state.c["tray_icon"].value
            TraySetIcon(internal_state.c["tray_icon"].value)
        } else {
            ; MsgBox "Setting to :: " script_meta.custom_icon_path
            TraySetIcon(script_meta.custom_icon_path)
        }
    } catch Error as e {
        log("WARN: Unable to update tray icon (make sure '" internal_state.c["tray_icon"].value "' is present)")
    }

    ; update state toggle
    internal_state.c["tray_icon"].toggle := toggle_state
    internal_state.save_all()
}

notify_user(notice_string := "", source_title := "bumper_state") {
    global cfg, script_meta

    if !notice_string {
        notice_string := source_title
        source_title := script_meta.display_name
    } {
        source_title := script_meta.display_name ":: " source_title
    }

    ; select what notification to send based on notificaiton mode
    append_log(notice_string)
    switch cfg.c["bump_notifications"].value {
        case 1:
            TrayTip(notice_string, source_title, 0x34)
        case 2:
            TrayTip(notice_string, source_title, 0x34)
            tooltip(notice_string)
            tooltip_timeout()
        default:
            ; do nothing
    }
}

; sends the remapped key when then triggered
remap_trigger() {
    global cfg
    send "{" cfg.c["remap_key"].value "}"
    tooltip("sending...", , , 4)
    tooltip_timeout(, 4)
}

fetch_updates() {
    global update_handler
    update_handler.check_for_updates(true)
}

/*
=================================================================================================
Older funcies
=================================================================================================
*/

prompt_update() {
    MsgBox "SelfUpdate currently disabled (as of v1.0.0)"
    ; if (version_request_variable.readyState != 4) {  ; Not done yet.
    ;     return
    ; }
    ; if (version_request_variable.status == 200) ; OK.
    ;     if newer_version(version_request_variable.responseText, app_version) == 1
    ;         msgbox "NEWER version (" strsplit(version_request_variable.responseText, "`r")[1] ") available`n`nhttps://chipy.dev"
    ;     else
    ;         TrayTip("Mouse Bumper on the latest version.", "Update Check (" app_version ")", "Mute")
}

fetch_latest_version_and_prompt(url) {
    ;version_request_variable := ComObject("Msxml2.XMLHTTP")
    version_request_variable.open("GET", url, true)
    version_request_variable.onreadystatechange := prompt_update  ;this sets a callback
    version_request_variable.send()
}

newer_version(v_one, v_two) {
    ; clean strings
    v_one := StrReplace(v_one, "`r", "")
    v_one := StrReplace(v_one, "`n", "")
    v_two := StrReplace(v_two, "`r", "")
    v_two := StrReplace(v_two, "`n", "")

    ; split the variables into arrays for easy testing
    v_one_array := StrSplit(v_one, ".")
    v_two_array := StrSplit(v_two, ".")

    ;debug msgbox "A (" v_one ")`nB (" v_two ")`nL " v_one_array.Length

    ; Check version lengths match
    if v_one_array.Length != v_two_array.Length
        return -1

    ; compare arrays until we find a larger one
    loop v_one_array.Length {
        ; try{
        ;debug msgbox Integer(v_one_array[A_Index]) "`n" Integer(v_two_array[A_Index])
        if Integer(v_one_array[A_Index]) > Integer(v_two_array[A_Index])
            return 1
        if Integer(v_one_array[A_Index]) < Integer(v_two_array[A_Index])
            return 2
        ; }catch{

        ; }
    }
    ; if we make it this far that v_two must be larger
    return 0
}

bump() {
    global cfg

    block_mouse := cfg.c["bump_interupt_protection"].value

    ; note on the screen to help know when bumps are attempted
    append_log("Bump triggering [blockinput=" block_mouse "]")
    ; check if auto_off is enabled AKA in use
    if cfg.c["auto_off_mins"].value > 0 {
        ;debug msgbox auto_off_start "`n" auto_off "`n" dateadd(auto_off_start, auto_off, "minutes") "`n" A_Now
        ; check if runtime is complete and disable bumper
        if dateadd(auto_off_start, cfg.c["auto_off_mins"].value, "minutes") < A_Now {
            cfg.c["bumper_active"].value := !cfg.c["bumper_active"].value
            append_log("Bumper DEACTIVATED (by AutoDisableTimer)")
            cfg.c["auto_off_mins"].value := 0
            save_settings()
            Restart
        }
    }


    ; calculate a idle time min.
    min_idle_time := 1000 + (cfg.c["bump_interval"].value * 0.2)
    ; safety break to prevent bumping while the mouse is in use
    if A_TimeIdle > min_idle_time and cfg.c["bumper_active"].value {

        ToolTip("Bumping...")
        ; Handle mouse_block
        if (!block_mouse) {
            if LOG_LEVEL <= 2
                tooltip("BLOCKED", 10, 10, 2)
            BlockInput "MouseMove"
        }


        ; get start time of bumpts
        start_tick := A_TickCount
        ; record mouse position before bump
        MouseGetPos(&OutputVarX, &OutputVarY)

        ; ; check for valid mouse coords and if invalid set to center width
        ; if OutputVarX > A_ScreenWidth*2
        ; 	OutputVarX := A_ScreenWidth//2

        ; loop for time period configured by user
        ; loop {

        ; Set TargetWindow active etc
        if cfg.c["target_window"].value {
            if WinExist(cfg.c["target_window"].value)
                WinActivate cfg.c["target_window"].value
        }

        ; generate random value for movement
        px_variance := cfg.c["bump_distance_variance"].value / 2
        rnd_x := random(0 - px_variance, px_variance)
        rnd_y := random(0 - px_variance, px_variance)
        dis_x := Floor((rnd_x + cfg.c["bump_distance"].value) * Random(-1, 1) + px_variance)
        dis_y := Floor((rnd_y + cfg.c["bump_distance"].value) * Random(-1, 1) + px_variance)


        ; toggle sendmode
        previous_sendmode := A_SendMode
        SendMode(cfg.c["bump_input_mode"].value)

        ; move mouse out by random value (or other modes)
        switch StrLower(cfg.c["bump_mode"].value) {
            case "centered":
                MouseMove((A_ScreenWidth // 2) + dis_x, (A_ScreenHeight // 2) + dis_y, cfg.c["bump_speed"].value, "R")

            case "relative":
                ; tooltip "START", OutputVarX, OutputVarY, 4
                ; tooltip "END", OutputVarX + dis_x, OutputVarY + dis_y, 5
                ; MsgBox "Mouse bumped from: " OutputVarX ":" OutputVarY "`nTO:`n" OutputVarX + dis_x ":" OutputVarY + dis_y "`nv:" cfg.c["bump_distance_variance"].value "`ndist:" cfg.c["bump_distance"].value "  [" dis_x ":" dis_y "]"

                ; SendMode("Input")
                ; MouseMove(OutputVarX, OutputVarY)
                ; SendMode("Event")
                MouseMove(dis_x, dis_y, cfg.c["bump_speed"].value, "R")


            default:
                SendMode("Input")
                MouseMove(OutputVarX, OutputVarY)
                SendMode("Event")
                MouseMove(dis_x, dis_y, cfg.c["bump_speed"].value, "R")
                MsgBox "No valid Bumper mode has been selected. Please assign a valid mode and try again. (valid modes should be listed in the info button of 'bumper_mode' setting)", "Missing Setting!", "icon! t10"

        }

        ; toggle sendmode
        SendMode(previous_sendmode)


        if cfg.c["mmo_mode"].value {
            send "{a down}"
            sleep 250
            send "{a up}"
            sleep 250
            send "{d down}"
            sleep 250
            send "{d up}"
        }


        ; ; note on the screen to help know when bumps happen
        ; ToolTip("MouseBumped")
        ; sleep to let mouse move
        sleep 100
        ; ; Check to see if we've met the duration count
        ; if A_TickCount - start_tick > bump_duration
        ;     break
        append_log("Bumping by " dis_x ":" dis_y "  (relative movement)")
        ; }
        ; return mouse to where it was
        MouseMove(OutputVarX, OutputVarY)
        append_log("Returning to " OutputVarX ":" OutputVarY)
    } else {
        ; not that this bump is being skipped
        if LOG_LEVEL < 2 {
            ToolTip("Activity detected")
            tooltip_timeout(, 1)
        }
        append_log("Mouse in use within the last " floor(min_idle_time) "ms so bump skipped")

    }

    ; Unblock
    if (!block_mouse) {
        BlockInput "MouseMoveOff"
        if LOG_LEVEL < 2 {
            tooltip("released...", 10, 10, 2)
            tooltip_timeout(1000, 2)

        }
    }

    ; wait 1second and hide the notification
    settimer((*) => ToolTip(""), -1000)
    ; shedule the next bump to allow for bump randomness and timely termination
    if cfg.c["bumper_active"].value
        settimer((*) => bump(), floor(0 - ((cfg.c["bump_interval"].value + random(0, cfg.c["bump_interval"].value * 0.01)))))
}

activate_bumper(*) {
    global
    cfg.c["bumper_active"].value := !cfg.c["bumper_active"].value
    if cfg.c["bumper_active"].value {
        ; mark the current time for auto off
        auto_off_start := A_Now
        ; determine how long we wait between bumps
        wait_time := floor(0 - (cfg.c["bump_interval"].value + random(0, cfg.c["bump_interval"].value * 0.01)))
        ; notify user
        str := "Interval: " round(abs(wait_time / 1000), 2) " sec"
        str .= "`nAuto-Disabling in " round(cfg.c["auto_off_mins"].value / 60) ":" round(mod(cfg.c["auto_off_mins"].value, 60))
        ; Moved here to update icon BEFORE notification pops
        Tray_setup()
        notify_user(str, "bumper_state:Activated")
        append_log("Activated with with " str)
        ; Start the first bump in XXXX time
        settimer((*) => bump(), wait_time)
    } else {
        ; Moved here to update icon BEFORE notification pops
        Tray_setup()
        notify_user("", "bumper_state:Deactivated")
    }
    ; Tray_setup()
    save_settings()
}

Restart(*) {
    append_log("Reloading")
    reload
}

terminate(*) {
    ExitApp
}

check_interval_vs_duration() {
    global cfg
    if cfg.c["bump_interval"].value < cfg.c["bump_duration"].value * 2 {
        msgbox "For safty sake Bump Interval has been altered to allow for time to disable the script if needed`nInterval was: " cfg.c["bump_interval"].value " and now will be: " cfg.c["bump_duration"].value * 2
        cfg.c["bump_interval"].value := cfg.c["bump_duration"].value * 2
    }
}

update_move_distance() {
    global cfg
    cfg.c["bump_distance"].value := InputBox("New distance to move mouse in pixels?", "Change Mouse Bump Distance", , cfg.c["bump_distance"].value).value
    save_settings()
    Tray_setup()
}

update_move_interval() {
    global cfg
    cfg.c["bump_interval"].value := InputBox("New interval to move mouse in milliseconds?`n1000 = 1 second`n300,000 = 5 minutes", "Change Mouse Bump Interval", , cfg.c["bump_interval"].value).value
    check_interval_vs_duration()
    save_settings()
    Tray_setup()
}

update_move_duration() {
    global bump_duration, bump_interval
    bump_duration := InputBox("New interval to move mouse in decaseconds?`n1000 = 1 second`n300,000 = 5 minutes", "Change Mouse Bump Duration", , bump_duration).value
    check_interval_vs_duration()
    save_settings()
    Tray_setup()
}

update_auto_off() {
    global cfg
    cfg.c["auto_off_mins"].value := InputBox("New time to run for before automatically turning off?`n60 = 1 Hour`n480 = 8 Hours/workday", "Change Runtime", , cfg.c["auto_off_mins"].value).value
    save_settings()
    Tray_setup()
}

update_mode() {
    global cfg
    cfg.c["bump_mode"].value := InputBox("New bumping mode (only valid option currently is 'centered' and 'other')", "Change bump mode", , cfg.c["bump_mode"].value).value
    save_settings()
    Tray_setup()
}

update_mmo() {
    global cfg
    cfg.c["mmo_mode"].value := InputBox("Toggle for MMOs to move left right with A and D when bumping (1 = on, 0 = off)", "Change MMO mode", , cfg.c["mmo_mode"].value).value
    save_settings()
    Tray_setup()
}

update_target_window() {
    global cfg

    info_string := "Name of the window to focus when attempting to do bumps (will not focus window if mouse is busy).`n`n"
    info_string .= "Make sure to prefix exe names with 'ahk_exe ' to help secure targeting."
    info_string .= "Example:`nahk_exe ms-teams.exe`nahk_exe msedge.exe"
    cfg.c["target_window"].value := InputBox(info_string, "Window to target", , cfg.c["target_window"].value).value
    save_settings()
    Tray_setup()
}

load_settings() {
    global

    cfg.load_all()
    binder.load_all()
    internal_state.load_all()

    ; move_distance := IniRead(cfg_path, "Settings", "bump_distance", "200")
    ; bump_interval := IniRead(cfg_path, "Settings", "bump_interval", "290000")
    ; bump_duration := IniRead(cfg_path, "Settings", "bump_duration", "2000")
    ; bump_mode := IniRead(cfg_path, "Settings", "bump_mode", "centered")
    ; ; bumper_active := IniRead(cfg_path, "Settings", "bumper_active", 0)
    ; auto_off_mins := IniRead(cfg_path, "Settings", "auto_off_mins", 0)
    ; ; log_mode := IniRead(cfg_path, "Settings", "log_mode", False)
    ; mmo_mode := IniRead(cfg_path, "Settings", "mmo_mode", False)
    ; target_window := IniRead(cfg_path, "Settings", "target_window", "ahk_exe ms-teams.exe")
}

save_settings() {
    global
    cfg.save_all()
    binder.save_all()
    internal_state.save_all()

    ; Iniwrite(move_distance, cfg_path, "Settings", "bump_distance")
    ; Iniwrite(bump_interval, cfg_path, "Settings", "bump_interval")
    ; Iniwrite(bump_duration, cfg_path, "Settings", "bump_duration")
    ; Iniwrite(bump_mode, cfg_path, "Settings", "bump_mode")
    ; ; Iniwrite(bumper_active, cfg_path, "Settings", "bumper_active")
    ; Iniwrite(auto_off_mins, cfg_path, "Settings", "auto_off_mins")
    ; ; Iniwrite(log_mode, cfg_path, "Settings", "log_mode")
    ; Iniwrite(mmo_mode, cfg_path, "Settings", "mmo_mode")
    ; Iniwrite(target_window, cfg_path, "Settings", "target_window")
}

Tray_setup() {
    global
    a_traymenu.delete()
    a_traymenu.add(script_label " v" app_version, (*) => fetch_updates())
    a_traymenu.add()
    if cfg.c["bumper_active"].value {
        a_traymenu.add("Toggle State 	(active)", activate_bumper.bind())
        a_traymenu.check("Toggle State 	(active)")
        ; mark the current time for auto off
        auto_off_start := A_Now
        ; run the initial bump to start the chain
        bump()
    } else {
        a_traymenu.add("Toggle State 	(inactive)", activate_bumper.bind())
    }
    a_traymenu.add("Run on Startup", (*) => run_script_on_startup("toggle"))
    if run_script_on_startup()
        a_traymenu.check("Run on Startup")
    a_traymenu.add("Testing (DevTrigger)", (*) => open_dev())
    a_traymenu.add()
    a_traymenu.add("Change Distance 	(" cfg.c["bump_distance"].value "px)", (*) => update_move_distance())
    a_traymenu.add("Change Interval 	(" cfg.c["bump_interval"].value "ms)", (*) => update_move_interval())
    a_traymenu.add("Change Duration 	(" bump_duration "ms)", (*) => update_move_duration())
    a_traymenu.add("Change Mode 	(" cfg.c["bump_mode"].value ")", (*) => update_mode())
    a_traymenu.add("Change MMO 	(" cfg.c["mmo_mode"].value ")", (*) => update_mmo())
    a_traymenu.add("Change AutoDisableTimer 	(" cfg.c["auto_off_mins"].value " mins)" DisplayCurrentTimePlus(cfg.c["auto_off_mins"].value), (*) => update_auto_off())
    a_traymenu.add("Change Taget App 	(" cfg.c["target_window"].value ")", (*) => update_target_window())
    a_traymenu.add()
    a_traymenu.add("Settings", (*) => open_settings())
    a_traymenu.add("Hotkeys", (*) => open_bindings())
    a_traymenu.add()
    a_traymenu.add("Restart", Restart.bind())
    a_traymenu.add("Exit", terminate.bind())

    a_traymenu.default := script_label " v" app_version

    ; update icon
    toggle_tray_icon(cfg.c["bumper_active"].value)
    ; refresh log_level
    LOG_LEVEL := cfg.c["log_level"].value

    append_log("SysTray setup complete`nChange Distance 	(" cfg.c["bump_distance"].value "ms)`nChange Interval 	(" cfg.c["bump_interval"].value "ms)`nChange Duration 	(" cfg.c["bump_duration"].value "ms)")


}

append_log(in_str) {
    global log_overflow
    try {
        log(log_overflow in_str)
        ; FileAppend(log_overflow FormatTime(A_Now, "yyyyMMdd HH:mm:ss") "|: " in_str "`n", "log.txt")
        log_overflow := ""
    } catch {
        log_overflow .= "LOF|" FormatTime(A_Now, "yyyyMMdd HH:mm:ss") "|: " in_str "`n"
        ToolTip "log_overflow created at " FormatTime(A_Now, "yyyyMMdd HH:mm:ss")
    }
}


/*
=================================================================================================
HotKeys
=================================================================================================
*/

; !^Down::
; {
;     click "right", "D"
;     click "left", "D"
;     sleep 20
;     click "right", "U"
;     click "left", "U"
; }


/*
Requirements
A GitHub repo with version tags like v1.0.0 or 1.0.0.
The release should have a .zip asset containing your updated AHK script.
7-Zip must be installed at the default path. You can adjust the path or use an AHK unzip library if needed.

#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\Lib\7ZipSimple.ahk ; Optional: for unzip functionality using 7-Zip

CURRENT_VERSION := "1.0.0" ; Replace with your app's current version
GITHUB_USER := "YourGitHubUsername"
GITHUB_REPO := "YourRepoName"

CheckForUpdate() {
    global CURRENT_VERSION, GITHUB_USER, GITHUB_REPO

    githubApiUrl := "https://api.github.com/repos/" GITHUB_USER "/" GITHUB_REPO "/releases/latest"
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    try {
        http.Open("GET", githubApiUrl)
        http.Send()
        if (http.Status != 200) {
            MsgBox "Failed to check for updates. HTTP status: " http.Status
            return
        }
        json := JSON.Parse(http.ResponseText)
        latestVersion := Trim(json.tag_name, "v") ; Remove leading 'v' if present
        if (CompareVersions(latestVersion, CURRENT_VERSION) > 0) {
            response := MsgBox("A new version (" latestVersion ") is available. Do you want to update?", "Update Available", 0x4)
            if (response == "Yes") {
                DownloadAndInstallUpdate(json)
            }
        } else {
            MsgBox "You're using the latest version (" CURRENT_VERSION ")."
        }
    } catch err {
        MsgBox "Error checking for update: " err.Message
    }
}

CompareVersions(v1, v2) {
    parts1 := StrSplit(v1, ".")
    parts2 := StrSplit(v2, ".")
    loop Max(parts1.Length, parts2.Length) {
        p1 := parts1.Has(A_Index) ? parts1[A_Index] : 0
        p2 := parts2.Has(A_Index) ? parts2[A_Index] : 0
        if (p1 != p2)
            return p1 - p2
    }
    return 0
}

DownloadAndInstallUpdate(json) {
    ; Find the .zip asset
    for asset in json.assets {
        if InStr(asset.name, ".zip") {
            zipUrl := asset.browser_download_url
            break
        }
    }

    if !zipUrl {
        MsgBox "Could not find a zip file in the latest release."
        return
    }

    tempZip := A_ScriptDir "\update.zip"
    destDir := A_ScriptDir "\update"

    ; Download ZIP
    try {
        UrlDownloadToFile(zipUrl, tempZip)
    } catch {
        MsgBox "Failed to download update zip."
        return
    }

    ; Ensure destination folder exists
    DirCreate(destDir)

    ; Unzip
    try {
        RunWait '"C:\Program Files\7-Zip\7z.exe" x "' tempZip '" -o"' destDir '" -y', , "Hide"
    } catch {
        MsgBox "Failed to unzip update. Ensure 7-Zip is installed."
        return
    }

    ; Find the new script (assuming same name)
    newScript := destDir "\" A_ScriptName
    if !FileExist(newScript) {
        MsgBox "Updated script not found at: " newScript
        return
    }

    ; Run new script and exit current
    Run newScript
    ExitApp
}

CheckForUpdate()
/*



















































