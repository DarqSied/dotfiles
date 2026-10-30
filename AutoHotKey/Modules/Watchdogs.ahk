; ==============================================================================
; [ MODULE: BACKGROUND WATCHDOGS & SNIPERS ]
; ==============================================================================

InitWatchdogs()

InitWatchdogs() {
    SetTimer(CheckSystemUptime, 3600000) 
    SetTimer(StartupAppHider, 1000)
    
    ; 1. Load the XInput hardware driver into memory
    global hXInput := DllCall("LoadLibrary", "Str", "xinput1_4.dll", "Ptr")
    
    ; 2. Extract the raw memory pointer for Ordinal 100 (XInputGetStateEx)
    global pXInputGetStateEx := hXInput ? DllCall("GetProcAddress", "Ptr", hXInput, "Ptr", 100, "Ptr") : 0
    
    ; 3. Engage the Watchdog ONLY if the pointer was successfully found
    if (pXInputGetStateEx) {
        SetTimer(ListenForGuideButton, 100) 
    } else {
        Notify("XInput Error", "Could not bind to Xbox Guide button.")
    }
}

CheckSystemUptime() {
    maxUptime := 259200000 
    
    if (A_TickCount >= maxUptime) {
        currentHours := Round(A_TickCount / 3600000)
        msg := "System uptime has reached " . currentHours . " hours.`n`n"
             . "To maintain low CPU uptime and clear memory leaks, a reboot is recommended.`n`n"
             . "Reboot now?"
             
        result := MsgBox(msg, "Maintenance: High Uptime Detected", "YesNo Icon! T120")
        
        if (result == "Yes" || result == "Timeout") {
            Shutdown(6) 
        }
    }
}

StartupAppHider() {
    static attempts := 0
    static closedWA := false
    static closedPL := false
    
    attempts++
    
    if (!closedWA && WinExist("WhatsApp")) {
        SetTimer(() => TryCloseWindow("WhatsApp"), -800)
        closedWA := true
    }
    if (!closedPL && WinExist("Phone Link")) {
        SetTimer(() => TryCloseWindow("Phone Link"), -800)
        closedPL := true
    }
    
    if ((closedWA && closedPL) || attempts >= 20) {
        SetTimer(StartupAppHider, 0)
    }
}

TryCloseWindow(winTitle) {
    try WinClose(winTitle)
}

; ------------------------------------------------------------------------------
; XINPUT WATCHDOG: Reads raw Xbox Guide Button hardware signal
; ------------------------------------------------------------------------------
ListenForGuideButton() {
    global pXInputGetStateEx
    static lastGuideState := false
    static xState := Buffer(16, 0)
    isGuidePressed := false
    
    Loop 4 {
        if (DllCall(pXInputGetStateEx, "UInt", A_Index - 1, "Ptr", xState) == 0) { 
            wButtons := NumGet(xState, 4, "UShort")
            if (wButtons & 0x0400) {
                isGuidePressed := true
                break
            }
        }
    }
    
    if (isGuidePressed && !lastGuideState) {
        playniteFS := EnvGet("LOCALAPPDATA") "\Playnite\Playnite.FullscreenApp.exe"
        
        if !ProcessExist("Playnite.FullscreenApp.exe") {
            if FileExist(playniteFS) {
                Run('"' playniteFS '"')
                Notify("Game Mode", "Playnite Fullscreen Launched")
            }
        } else {
            try WinActivate("ahk_exe Playnite.FullscreenApp.exe")
        }
    }
    
    lastGuideState := isGuidePressed
}