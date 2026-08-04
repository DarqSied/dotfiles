; Engage the watchdog to check the battery every 60,000 ms (1 minute)
SetTimer(CheckBatteryStatus, 60000)

; ==============================================================================
; SYSTEM API HOOK: BATTERY & CHARGER STATUS
; ==============================================================================
CheckBatteryStatus() {
    ; Static variable remembers if we already warned you, so it doesn't spam you
    static alerted := false 
    
    ; Create a 12-byte buffer to receive the SYSTEM_POWER_STATUS data from Windows
    powerStatus := Buffer(12, 0)
    
    if DllCall("kernel32\GetSystemPowerStatus", "Ptr", powerStatus) {
        
        ; Read Byte 0 (AC Status): 0 = Offline (Unplugged), 1 = Online (Plugged In)
        acLineStatus := NumGet(powerStatus, 0, "UChar") 
        
        ; Read Byte 2 (Battery %): 0 to 100
        batteryPercent := NumGet(powerStatus, 2, "UChar") 
        
        ; If plugged in AND fully charged
        if (acLineStatus == 1 && batteryPercent >= 100) {
            if (!alerted) {
                ; Play an audible beep to get your attention
                SoundBeep(750, 500) 
                
                ; Show a Windows notification bubble
                TrayTip("🔋 Battery at 100%", "Please unplug your charger to preserve battery health.", "Iconi Mute")
                
                alerted := true ; Mark as alerted so it doesn't loop
            }
        } 
        ; If unplugged (running on battery)
        else if (acLineStatus == 0) {
            ; Reset the flag so it will warn you again during your next charge
            alerted := false 
        }
    }
}