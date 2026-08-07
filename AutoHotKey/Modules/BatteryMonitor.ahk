; ==============================================================================
; [ MODULE: BATTERY & CHARGING WATCHDOG ]
; ==============================================================================

InitBatteryMonitor()

InitBatteryMonitor() {
    ; Engage the watchdog to check the battery every 60,000 ms (1 minute)
    SetTimer(CheckBatteryStatus, 60000)
}

; ------------------------------------------------------------------------------
; SYSTEM API HOOK: BATTERY & CHARGER STATUS
; ------------------------------------------------------------------------------
CheckBatteryStatus() {
    static alerted := false 
    powerStatus := Buffer(12, 0)
    
    if DllCall("kernel32\GetSystemPowerStatus", "Ptr", powerStatus) {
        
        acLineStatus := NumGet(powerStatus, 0, "UChar") 
        batteryPercent := NumGet(powerStatus, 2, "UChar") 
        
        if (acLineStatus == 1 && batteryPercent >= 100) {
            if (!alerted) {
                SoundBeep(750, 500) 
                TrayTip("🔋 Battery at 100%", "Please unplug your charger to preserve battery health.", "Iconi Mute")
                alerted := true 
            }
        } 
        else if (acLineStatus == 0) {
            alerted := false 
        }
    }
}