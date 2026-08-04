; ==============================================================================
; [ MAIN HUB ] - SYSTEM LAUNCHER
; ==============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
A_MenuMaskKey := "vkE8"
ProcessSetPriority("High") ; Give AHK enough CPU priority to beat the DWM render delay

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

; Load Automations
#Include "%A_ScriptDir%\Modules\FocusEngine.ahk"
#Include "%A_ScriptDir%\Modules\BatteryMonitor.ahk"

; Helper: Verify if the active window is an officially launched PWA
IsVaultedPWA(hwnd) {
    global PWAVault
    if IsSet(PWAVault) {
        for appName, vaultHwnd in PWAVault {
            if (hwnd == vaultHwnd)
                return true
        }
    }
    return false
}

; SUSPEND & HIDE INTERCEPTOR
; Only triggers if the window is in the MediaPWAs group AND inside the Vault
#HotIf WinActive("ahk_group MediaPWAs") && IsVaultedPWA(WinExist("A"))

$#q::  ; The '$' forces AHK to only respond to physical key presses
$!F4:: 
$^w::  
{
    activeHwnd := WinExist("A")
    if (!activeHwnd)
        return
        
    Send("{Blind}{vkE8}{LWin up}{RWin up}{Alt up}{Ctrl up}{Shift up}")
    Sleep(50) 
    
    Send("^!x")
    Sleep(300) 
    WinMinimize(activeHwnd)
    WinHide(activeHwnd)
    
    Notify("Media Stopped", "Playback paused successfully.")
}
#HotIf

; BOOT SEQUENCE
Initialize()