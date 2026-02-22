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
1.1.1
- [x] Added manual update query (by clicking script name in TrayMenu)
- [x] Added example ahk_exe
1.1.4
- [x] Added tray hover name
- [x] Moved DevTest in trayMenu
- [x] Added log_level info in settings
- [x] Adjust log_level to report boot and bump @level4 leaving ONLY ERRors on default 5
- [x] Improved update prompt
1.1.5
- [x] Improved auto-disable timer
- [ ] Add detection modes (timer-based vs idle-based)
1.1.6
MOVED TO GITHUB notes
https://github.com/iamchipy/chipys-human-interface-device-extension

*/

#include ..\chipys-ahk-library\chipys-ahk-library.ahk


#SingleInstance
Persistent
; sendmode "event"
sendmode "Input"
SetMouseDelay 25

app_version := "1.1.8", unused := "custom var"
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
GUI_FONT_SIZE := 22


coded_on := "2.0.19"
if A_AhkVersion != coded_on and !A_IsCompiled
    msgbox "You are running AHK v" A_AhkVersion "`n`rThis code was writting on v" coded_on "`n`nPlease download that exact version from autohotkey.com/download/2.0/"

log_overflow := ""
is_first_execution := true


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
cfg.ini("font_scaler", , 22, "edit", "Controles the size of the GUI (settings/hotkeys) fonts.`n`n15 - Recommended min`n36 - Recommended max`n(Default:20)")
cfg.ini("target_window", , "", "edit", "Name of winow/app that should receive focus for winow-specific actions.`nConsists of a PREFIX (ahk_exe, ahk_class, ahk_id) and a windowHDL`n`nUse 'ahk_exe ' and then the 'APP.exe' name for easiest user reference.")
cfg.ini("log_level", , "REPORT", "DropDownList",
    "Sets logging level, lower value = more detail. `n`n" .
    LogLevel.descriptions() "`n`n(Default: REPORT/10)",
    LogLevel.options_as_array())
; Bump settings
cfg.ini("bump_interupt_protection", , 1, "checkbox", "Bump protection help prevent script interupting actively used mouse. (disabling this will block mouse inputs for the duration of the bump action)`n(Default:1)")
cfg.ini("bump_position_memory", , 1, "checkbox", "When enabled, attempts to return mouse to it's original coordinates after bumping.`n(Default:1)")
cfg.ini("bump_mode", , "relative", "edit", "BumpMode determines how the script attempts to move the mouse.`n`nCurrent options:`n'Centered' - Mouse is moved to center of active monitor and then bumped bump_distance pixels in a random direction.`n'Relative' - Mouse moves bump_distance pixels relative to it's current position`n'Minimum' - Mouse is moved to bump_distance from 0:0 and then bumped bump_distance pixels in a random direction.  `n(Default:Relative)")
; cfg.ini("auto_off_mins", , 0, "edit", "DISCONTINUED`n`nNew time to run for before automatically turning off?`n60 = 1 Hour`n480 = 8 Hours/workday")
cfg.ini("mmo_mode", , 0, "edit", "Toggle for MMOs to move left right with A and D when bumping (1 = on, 0 = off)`n(Default:0)")
cfg.ini("bump_distance_variance", , 50, "edit", "Distance in pixels to use as random variance range. `n(Default: 50)")
cfg.ini("bump_distance", , 500, "edit", "Distance in pixels to move the mouse when bumping it. `n(Default: 500)")
cfg.ini("bump_interval", , 290000, "edit", "Time in ms between bump checks. The bump will be skipped if the mouse has been active within min_idle_time (2sec + ~5% of time value) `n60,000 = 1 minute `n300,000 = 5 minutes.`n(Default:290,000)")
cfg.ini("bump_duration", , 1000, "edit", "REPLACED (v1.1.0) by 'bump_speed'`nTime in ms to be moving the mouse. AKA duration of the bump. ")
cfg.ini("bump_input_mode", , "Event", "edit", "Set the input mode for the bump event. Interacts with bump_speed setting.`n'Event' will emulate mouse movements better. `n'Input' will be faster.(failing to trigger idle timeout reset on some systems)`n(Default: 'Event')")
cfg.ini("bump_speed", , 15, "edit", "Speed is the movement speed of the mouse during the bump motion. Range 0-100 lower is faster `n(Default:15)")
cfg.ini("bump_notifications", , 2, "edit",
    "Set which items you want to receive Windows(Toaster) Notification pop-ups for. To select multiple simply add all values together.`n`n" .
    "0 - off`n" .
    "1 - Script successful reboot`n" .
    "2 - Script updates`n" .
    "4 - Mouse bumper state changes`n" .
    "8 - Mouse bumper auto-off feautre (when enabled and triggered)")
cfg.ini("bumper_active", , , "Checkbox", "Toggle to track the active state of the bumper")
cfg.ini("bumper_timeout", , , "Time", "Select a time of day for the bumper to automatically turn self off. `n`nFOR NOW the only way to disable this is to manually delete the value from the CFG file.")
; Remapper settings
cfg.ini("remap_key", , , "edit", "Set the input key to be played/used`n`n" HOTKEY_CHEATSHEET)
; AutoClicker
cfg.ini("auto_click_key", , "LBUTTON", "edit", "Set the input key to be repeated`n`n" HOTKEY_CHEATSHEET)
cfg.ini("auto_click_interval", , 1000, "edit", "Set the interval in ms between each auto-click repedition")
cfg.ini("auto_click_active", , , "Checkbox", "Toggle to track the active state of the auto input repeating AutoClick")

; internal state trackers
global state := ConfigManagerTool(cfg_path, "state", , script_meta)
state.ini("tray_icon", , "chide_active.ico", "edit", "", ["toggle", "*1"])
state.ini("time_since_last_bump", , 0, "edit", "")
state.ini("bump_interval_with_random")
state.ini("last_bump_tick")


version_request_variable := ComObject("Msxml2.ServerXMLHTTP")
load_settings()
activate_bumper()  ; needs to happen before tray_setup to sync state of bumper
Tray_setup()

; testing update pull
global update_handler := UpdateHandler(, script_meta.app_version, script_meta.file_name, script_meta.display_name, "chipys-human-interface-device-extension")


notify_user(build_tray_string(cfg.c["bumper_active"].value, cfg.c["auto_off_mins"].value), " v" app_version " Ready!")
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

; Build the string for TrayTip (toaster) notificaiton of current state on reboot
build_tray_string(bumper_state, auto_off_mins) {
    tip_string := bumper_state ? "Mode: Active" : "Mode: Inactive"
    if auto_off_mins
        tip_string .= bumper_timeout_remaining()
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

    ; ; test write perms
    ; if (MsgBox("Will now attempt to write to file:: " LOG_PATH, "TEST?", "icon? yn") = "yes") {

    ;     FileAppend(FormatTime(A_Now, "yyyyMMdd HH:mm:ss") "|: DEV TEST STRING`n", LOG_PATH)
    ;     MsgBox "If you've seen no errors it likely worked, will attempt to open logs now"
    ;     run(LOG_PATH)
    ; }

    ; Testing hte UITool
    test_prompt := UITool.UpdatePrompt((*) => tooltip("YOU HIT YES"), "Test Title", "Do you want to APPROVE?!", "Body text for this approval reques")
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

toggle_tray_icon(toggle_state := -1) {
    global state, script_meta
    ; Set defaults if we arn't being directed to set a given state
    if (toggle_state == -1) {
        toggle_state := !state.c["tray_icon"].toggle
    }

    try {
        ; execute toggle
        if (toggle_state and state.c.Has("tray_icon")) {
            ; MsgBox "Setting to :: " internal_state.c["tray_icon"].value
            TraySetIcon(state.c["tray_icon"].value)
        } else {
            ; MsgBox "Setting to :: " script_meta.custom_icon_path
            TraySetIcon(script_meta.custom_icon_path)
        }
    } catch Error as e {
        log("WARN: Unable to update tray icon (make sure '" state.c["tray_icon"].value "' is present)")
    }

    ; update state toggle
    state.c["tray_icon"].toggle := toggle_state
    state.save_all()
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
    append_log("[ALERT] " notice_string)

    ; now we address each notice function in decending order
    notice_tracker := cfg.c["bump_notifications"].value

    ;     "8 - Mouse bumper auto-off feautre (when enabled and triggered)") "Set which items you want to receive Windows(Toaster) Notification pop-ups for. To select multiple simply add all values together.`n`n" .
    ; "0 - off`n" .
    ; "1 - Script successful reboot`n" .
    ; "2 - Script updates`n" .
    ; "4 - Mouse bumper state changes`n" .
    ; "8 - Mouse bumper auto-off feautre (when enabled and triggered)")


    ; #4 toster for update success
    if notice_tracker >= 4 {
        notice_tracker -= 4
        if notice_string and RegExMatch(notice_string, "i)ctivated") {
            TrayTip(notice_string, source_title, 0x34)
        }
    }

    ; #2 toster for update success
    if notice_tracker >= 2 {
        notice_tracker -= 2
        if notice_string and RegExMatch(notice_string, "i)update|latest") {
            TrayTip(notice_string, source_title, 0x34)
            tooltip(notice_string)
            tooltip_timeout()
        }
    }

    ; #1 toaster for reboots
    if notice_tracker >= 1 {
        notice_tracker -= 1
        if notice_string and RegExMatch(notice_string, "i)eboot") {
            TrayTip(notice_string, source_title, 0x34)
        }
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

bumper_debug_display(interval := 2000) {
    global state, cfg

    if (A_TimeIdle > 1000) {
        display_str := "idle for " Format("{1}:{2:02}", Floor(A_TimeIdle / 60000), Floor(Mod(A_TimeIdle, 60000) / 1000))
        disp(display_str, 2, , interval * 0.99)

        ticks_till_bump := (state.c["last_bump_tick"].value + Abs(state.c["bump_interval_with_random"].value)) - A_TickCount
        display_str := "bump in " Format("{1}:{2:02}", Floor(ticks_till_bump / 60000), Floor(Mod(ticks_till_bump, 60000) / 1000))
        disp(display_str, 1, , interval * 0.99)
    }

    if cfg.c["bump_notifications"].value > 2 {
        settimer((*) => bumper_debug_display(), 0 - interval)
    }
}

roll_for(variable := 0, variance := 0.05, multiplier := -1) {
    return floor(variable + random(0, variable * 0.01)) * multiplier
}

roll_new_bump_interval_variations() {
    global state, cfg
    state.c["bump_interval_with_random"].value := roll_for(cfg.c["bump_interval"].value)

}

bumper_timeout_remaining(mode := "str") {
    global cfg
    ; trim-off date
    trimmed_timeout_remaining := SubStr(cfg.c["bumper_timeout"].value, 9)
    ; Create a new timestamp using TODAY'S date + the SELECTED time
    normalized_timeout := A_YYYY . A_MM . A_DD . trimmed_timeout_remaining
    remaining_minutes := DateDiff(normalized_timeout, A_Now, "Minutes")
    shutoff_time := DateAdd(A_Now, remaining_minutes, "Minutes")

    out_string := "N/A"
    switch StrLower(mode) {
        case "str":
            ; manually build value
            abs_minutes := Abs(remaining_minutes)
            hours := abs_minutes // 60
            minutes := mod(abs_minutes, 60)
            out_string := hours ":" minutes " (" FormatTime(shutoff_time, "h:mmtt") ")"
        default:
    }

    return out_string
}

/*
=================================================================================================
Older funcies
=================================================================================================
*/


bump() {
    global cfg, state

    block_mouse := cfg.c["bump_interupt_protection"].value

    ; note on the screen to help know when bumps are attempted
    append_log("[INFO]Bump triggering [blockinput=" block_mouse "]")
    ; check if auto_off is enabled AKA in use
    if cfg.c["auto_off_mins"].value > 0 {
        ;debug msgbox auto_off_start "`n" auto_off "`n" dateadd(auto_off_start, auto_off, "minutes") "`n" A_Now
        ; check if runtime is complete and disable bumper
        if dateadd(auto_off_start, cfg.c["auto_off_mins"].value, "minutes") < A_Now {
            cfg.c["bumper_active"].value := !cfg.c["bumper_active"].value
            append_log("[ALERT]Bumper DEACTIVATED (by AutoDisableTimer)")
            cfg.c["auto_off_mins"].value := 0
            save_settings()
            Restart
        }
    }


    ; calculate a idle time min.
    min_idle_time := 2000 + (cfg.c["bump_interval"].value * 0.05)
    ; safety break to prevent bumping while the mouse is in use
    if A_TimeIdle > min_idle_time and cfg.c["bumper_active"].value {

        ToolTip("Bumping...")
        ; Handle mouse_block
        if (!block_mouse) {
            if LOG_LEVEL <= 2
                tooltip("BLOCKED", 10, 10, 2)
            BlockInput "MouseMove"
        }

        ; record mouse position before bump
        MouseGetPos(&OutputVarX, &OutputVarY)

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
                ; If we are using Centered mode we reset mouse to the center of the screen then move it
                c_x := (A_ScreenWidth // 2)
                c_y := (A_ScreenHeight // 2)
                append_log("[DEBUG]Bump moving " dis_x ":" dis_y " (centered with " c_x ":" c_y ")")
                ; snap to center with 0 for instant movement
                MouseMove(c_x, c_y, 0)
                ; move mouse by desired value relative to center
                MouseMove(c_x + dis_x, c_y + dis_y, cfg.c["bump_speed"].value, "R")

            case "minimum":
                ; If we are using Centered mode we reset mouse to the center of the screen then move it
                append_log("[DEBUG]Bump moving " dis_x ":" dis_y " (centered with " cfg.c["bump_distance"].value ":" cfg.c["bump_distance"].value ")")
                ; snap to center with 0 for instant movement
                MouseMove(cfg.c["bump_distance"].value, cfg.c["bump_distance"].value, 0)
                ; move mouse by desired value relative to center
                MouseMove(c_x + dis_x, c_y + dis_y, cfg.c["bump_speed"].value, "R")

            case "relative":
                append_log("[DEBUG]Bump moving " dis_x ":" dis_y " (relative to " OutputVarX ":" OutputVarY ")")
                MouseMove(dis_x, dis_y, cfg.c["bump_speed"].value, "R")

            default:
                SendMode("Input")
                MouseMove(OutputVarX, OutputVarY)
                SendMode("Event")
                MouseMove(dis_x, dis_y, cfg.c["bump_speed"].value, "R")
                MsgBox "No valid Bumper mode has been selected. Please assign a valid mode and try again. (valid modes should be listed in the info button of 'bumper_mode' setting)", "Missing Setting!", "icon! t10"
                append_log("[ERROR] Invalid bump_mode set, defaulting to event&relative!")
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

        ; sleep to let mouse move
        sleep 100


        if (cfg.c["bump_position_memory"].value) {
            ; return mouse to where it was
            MouseMove(OutputVarX, OutputVarY)
            append_log("[DEBUG]Returning to " OutputVarX ":" OutputVarY)
        }
    } else {
        ; not that this bump is being skipped
        if LOG_LEVEL < 2 {
            ToolTip("Activity detected")
            tooltip_timeout(, 1)
        }
        append_log("[INFO]Mouse in use within the last " floor(min_idle_time) "ms so bump skipped")

    }

    ; Unblock
    if (!block_mouse) {
        BlockInput "MouseMoveOff"
        if LOG_LEVEL <= LogLevel.DEBUG {
            tooltip("released...", 10, 10, 2)
            tooltip_timeout(1000, 2)

        }
    }

    ; wait 1second and hide the notification
    settimer((*) => ToolTip(""), -1000)
    ; shedule the next bump to allow for bump randomness and timely termination
    ; Currently BumpInterval + (1% variance) rounded down
    state.c["last_bump_tick"].value := A_TickCount

    roll_new_bump_interval_variations()
    if cfg.c["bumper_active"].value
        settimer((*) => bump(), state.c["bump_interval_with_random"].value)
}

activate_bumper(*) {
    global is_first_execution, cfg, state

    ; special logic for state toggling (FIRST RUN exception to trigger on boot)
    if is_first_execution
        is_first_execution := false
    else
        cfg.c["bumper_active"].value := !cfg.c["bumper_active"].value

    if cfg.c["bumper_active"].value {
        ; mark the current time for auto off
        auto_off_start := A_Now
        ; determine how long we wait between bumps

        roll_new_bump_interval_variations()
        state.c["last_bump_tick"].value := A_TickCount
        ; notify user
        str := "Interval: " round(abs(state.c["bump_interval_with_random"].value / 1000), 2) " sec"
        str .= "`nAuto-Disabling in " round(cfg.c["auto_off_mins"].value / 60) ":" round(mod(cfg.c["auto_off_mins"].value, 60))
        ; Moved here to update icon BEFORE notification pops
        Tray_setup()
        notify_user(str, "bumper_state:Activated")
        append_log("[DEBUG]Activated with with " str)
        ; Start the first bump in XXXX time
        settimer((*) => bump(), state.c["bump_interval_with_random"].value)


        if cfg.c["bump_notifications"].value > 2 {
            settimer((*) => bumper_debug_display(), -1000)
        }
    } else {
        ; Moved here to update icon BEFORE notification pops

        Tray_setup()
        notify_user("", "bumper_state:Deactivated")
    }
    ; Tray_setup()
    save_settings()
}

Restart(*) {
    append_log("[INFO]Reloading")
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
    global cfg
    cfg.c["bump_duration"].value := InputBox("New interval to move mouse in decaseconds?`n1000 = 1 second`n300,000 = 5 minutes", "Change Mouse Bump Duration", , cfg.c["bump_duration"].value).value
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
    state.load_all()

}

save_settings() {
    global
    cfg.save_all()
    binder.save_all()
    state.save_all()
}

Tray_setup() {
    global

    ; First section
    a_traymenu.delete()
    script_name_with_version := script_label " v" app_version
    a_traymenu.add(script_name_with_version, (*) => fetch_updates())
    A_IconTip := script_name_with_version

    ; Secind section
    a_traymenu.add()
    ; ; Toggle info
    if cfg.c["bumper_active"].value {
        A_IconTip .= " (active)"
        toggle_bumper_label := "Toggle State 	(active)"
        ; mark the current time for auto off
        auto_off_start := A_Now
    } else {
        A_IconTip .= " (inactive)"
        toggle_bumper_label := "Toggle State 	(inactive)"
    }
    a_traymenu.add(toggle_bumper_label, activate_bumper.bind())
    a_traymenu.default := toggle_bumper_label
    if (cfg.c["bumper_active"].value)
        a_traymenu.check(toggle_bumper_label)
    ; ; RunOnStartup state
    a_traymenu.add("Run on Startup", (*) => run_script_on_startup("toggle"))
    if run_script_on_startup()
        a_traymenu.check("Run on Startup")
    a_traymenu.add("Testing (DevTrigger)", (*) => open_dev())

    ; Section 3
    a_traymenu.add()
    a_traymenu.add("Change Distance 	(" cfg.c["bump_distance"].value "px)", (*) => update_move_distance())
    a_traymenu.add("Change Interval 	(" cfg.c["bump_interval"].value "ms)", (*) => update_move_interval())
    a_traymenu.add("Change Duration 	(" cfg.c["bump_duration"].value "ms)", (*) => update_move_duration())
    a_traymenu.add("Change Mode 	(" cfg.c["bump_mode"].value ")", (*) => update_mode())
    a_traymenu.add("Change MMO 	(" cfg.c["mmo_mode"].value ")", (*) => update_mmo())
    a_traymenu.add("Change AutoDisableTimer 	" bumper_timeout_remaining(), (*) => update_auto_off())
    a_traymenu.add("Change Taget App 	(" cfg.c["target_window"].value ")", (*) => update_target_window())
    a_traymenu.add()
    a_traymenu.add("Settings", (*) => open_settings())
    a_traymenu.add("Hotkeys", (*) => open_bindings())
    a_traymenu.add()
    a_traymenu.add("Restart", Restart.bind())
    a_traymenu.add("Exit", terminate.bind())

    ; Apply other settings
    apply_general_settings()

    append_log("[INFO]SysTray setup complete`nChange Distance 	(" cfg.c["bump_distance"].value "ms)`nChange Interval 	(" cfg.c["bump_interval"].value "ms)`nChange Duration 	(" cfg.c["bump_duration"].value "ms)")

    ;add A_IconTip Traytip IconTooltip
    if !A_IsCompiled
        A_IconTip .= "[DEV]"
}

apply_general_settings() {
    global cfg, GUI_FONT_SIZE, LOG_LEVEL

    ; Set the tray icon
    toggle_tray_icon(cfg.c["bumper_active"].value)

    ; refresh log_level
    LOG_LEVEL := LogLevel(cfg.c["log_level"].value)
    ; Set font scale
    GUI_FONT_SIZE := cfg.c["font_scaler"].value

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