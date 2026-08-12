; ==============================================================================
; [ MAIN HUB ] - SYSTEM LAUNCHER
; ==============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
A_MenuMaskKey := "vkE8"
ProcessSetPriority("High")

; Load Configurations & Core Engine
#Include "%A_ScriptDir%\Modules\Config.ahk"
#Include "%A_ScriptDir%\Modules\InitHooks.ahk"
#Include "%A_ScriptDir%\Modules\Utilities.ahk"
#Include "%A_ScriptDir%\Modules\TrayMenu.ahk"

; Load Function Libraries
#Include "%A_ScriptDir%\Modules\CaptureEngine.ahk"
#Include "%A_ScriptDir%\Modules\Router.ahk"
#Include "%A_ScriptDir%\Modules\WindowManager.ahk"
#Include "%A_ScriptDir%\Modules\Cheatsheet.ahk"

; Load Triggers (Hotstrings & Keybindings)
#Include "%A_ScriptDir%\Modules\Hotstrings.ahk"
#Include "%A_ScriptDir%\Modules\Keybindings.ahk"

; Load Automations & Watchdogs
#Include "%A_ScriptDir%\Modules\FocusEngine.ahk"
#Include "%A_ScriptDir%\Modules\BatteryMonitor.ahk"
#Include "%A_ScriptDir%\Modules\Watchdogs.ahk"

; BOOT SEQUENCE
Initialize()