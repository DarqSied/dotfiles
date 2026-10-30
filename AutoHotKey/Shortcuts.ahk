; ==============================================================================
; [ MAIN HUB ] - SYSTEM LAUNCHER
; ==============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
A_MenuMaskKey := "vkE8"
ProcessSetPriority("High")

; 1. Load Core Definitions & Pure Function Libraries
#Include "%A_ScriptDir%\Modules\Config.ahk"
#Include "%A_ScriptDir%\Modules\Utilities.ahk"
#Include "%A_ScriptDir%\Modules\InitHooks.ahk"
#Include "%A_ScriptDir%\Modules\TrayMenu.ahk"
#Include "%A_ScriptDir%\Modules\CaptureEngine.ahk"

; 2. Run Core Boot Sequence FIRST (Loads VDA.dll, Taskbar, and Shell Hooks)
Initialize()

; 3. Load & Auto-Start Background Engines (No Hotkeys Inside)
#Include "%A_ScriptDir%\Modules\WindowManager.ahk"
#Include "%A_ScriptDir%\Modules\Router.ahk"
#Include "%A_ScriptDir%\Modules\BatteryMonitor.ahk"
#Include "%A_ScriptDir%\Modules\Watchdogs.ahk"

; 4. Load Modules Containing Hotkeys & Hotstrings Last
#Include "%A_ScriptDir%\Modules\FocusEngine.ahk"
#Include "%A_ScriptDir%\Modules\Cheatsheet.ahk"
#Include "%A_ScriptDir%\Modules\Hotstrings.ahk"
#Include "%A_ScriptDir%\Modules\Keybindings.ahk"