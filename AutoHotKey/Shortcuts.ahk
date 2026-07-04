; ==============================================================================
; [ MAIN HUB ] - SYSTEM LAUNCHER
; ==============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
A_MenuMaskKey := "vkE8"
ProcessSetPriority("High") ; Give AHK enough CPU priority to beat the DWM render delay

; --- 1. Load Configurations & Core Engine ---
#Include "%A_ScriptDir%\Modules\Config.ahk"
#Include "%A_ScriptDir%\Modules\InitHooks.ahk"
#Include "%A_ScriptDir%\Modules\Utilities.ahk"
#Include "%A_ScriptDir%\Modules\TrayMenu.ahk"

; --- 2. Load Function Libraries ---
#Include "%A_ScriptDir%\Modules\CaptureEngine.ahk"
#Include "%A_ScriptDir%\Modules\Router.ahk"
#Include "%A_ScriptDir%\Modules\WindowManager.ahk"
#Include "%A_ScriptDir%\Modules\Cheatsheet.ahk"

; --- 3. Load Triggers (Hotstrings & Keybindings) ---
#Include "%A_ScriptDir%\Modules\Hotstrings.ahk"
#Include "%A_ScriptDir%\Modules\Keybindings.ahk"

; ------------------------------------------------------------------------------
; SUSPEND & HIDE INTERCEPTOR
; ------------------------------------------------------------------------------
#HotIf WinActive("ahk_group MediaPWAs")
#q::
!F4:: 
^w::  
{
    activeHwnd := WinExist("A")
    if (!activeHwnd)
        return
        
    Send("{Blind}{LWin up}{RWin up}{Alt up}{Ctrl up}{Shift up}")
    Sleep(50) 
    
    Send("^!x")
    Sleep(300) 
    WinMinimize(activeHwnd)
    WinHide(activeHwnd)
    
    Notify("Media Stopped", "Playback paused successfully.")
}
#HotIf

; ------------------------------------------------------------------------------
; BOOT SEQUENCE
; ------------------------------------------------------------------------------
Initialize()