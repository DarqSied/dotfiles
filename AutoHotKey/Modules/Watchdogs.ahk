; ==============================================================================
; [ MODULE: BACKGROUND WATCHDOGS & SNIPERS ]
; ==============================================================================

InitWatchdogs()

InitWatchdogs() {
    SetTimer(CheckSystemUptime, 3600000) 
    SetTimer(HideWhatsApp, 1000)
    SetTimer(HidePhoneLink, 1000)
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