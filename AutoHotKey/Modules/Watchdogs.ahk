; ==============================================================================
; [ MODULE: BACKGROUND WATCHDOGS & SNIPERS ]
; ==============================================================================

InitWatchdogs()

InitWatchdogs() {
    SetTimer(CheckSystemUptime, 3600000) 
    SetTimer(HideWhatsApp, 1000)
    SetTimer(HidePhoneLink, 1000)
    
    ; 1. Load the XInput hardware driver into memory
    global hXInput := DllCall("LoadLibrary", "Str", "xinput1_4.dll", "Ptr")
    
    ; 2. Extract the raw memory pointer for Ordinal 100 (XInputGetStateEx)
    global pXInputGetStateEx := DllCall("GetProcAddress", "Ptr", hXInput, "Ptr", 100, "Ptr")
    
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

HideWhatsApp() {
    static attemptsWA := 0
    attemptsWA++
    if WinExist("WhatsApp") {
        Sleep(800) 
        WinClose("WhatsApp") 
        SetTimer(HideWhatsApp, 0)
    } else if (attemptsWA >= 20) {
        SetTimer(HideWhatsApp, 0)
    }
}

HidePhoneLink() {
    static attemptsPL := 0
    attemptsPL++
    if WinExist("Phone Link") {
        Sleep(800)
        WinClose("Phone Link") 
        SetTimer(HidePhoneLink, 0) 
    } else if (attemptsPL >= 20) {
        SetTimer(HidePhoneLink, 0) 
    }
}

; ------------------------------------------------------------------------------
; XINPUT WATCHDOG: Reads raw Xbox Guide Button hardware signal
; ------------------------------------------------------------------------------
ListenForGuideButton() {
    global pXInputGetStateEx
    static lastGuideState := false
    xState := Buffer(16, 0)
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