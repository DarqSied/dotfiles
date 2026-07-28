; ==============================================================================
; [ MODULE: HYBRID SCREENSHOT ENGINE ]
; ==============================================================================

global ShareXPath := '"C:\Program Files\ShareX\ShareX.exe"' 

PerformCapture(mode) {
    ; 1. Empty the clipboard for the watchdog
    A_Clipboard := ""
    
    ; 2. Trigger the appropriate engine
    if (mode = "Scrolling") {
        ; Wake ShareX for scrolling captures
        if not ProcessExist("ShareX.exe") {
            Run(ShareXPath ' -silent')
            WinWait("ahk_exe ShareX.exe",, 5)
            Sleep(1000) ; Buffer for cold boot
        }
        Run(ShareXPath ' -ScrollingCapture')
    } else if (mode = "Region") {
        Send("#+s") 
    } else if (mode = "FullScreen") {
        Send("{PrintScreen}") 
    } else if (mode = "Window") {
        Send("!{PrintScreen}") 
    }
    
    ; 3. The Watchdog: Wait up to 120 seconds for clipboard data
    if ClipWait(10, 1) {
        
        Sleep(300) ; Brief buffer to let the clipboard finalize the image data
        
        ; 4. Directory Setup
        currentMonth := FormatTime(, "yyyy-MM")
        targetDir := "C:\Users\himan\Downloads\Synced\Screenshots\" currentMonth
        
        if not DirExist(targetDir) {
            DirCreate(targetDir)
        }
        
        ; 5. Generate 10-Character Filename
        chars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        randStr := ""
        Loop 10
            randStr .= SubStr(chars, Random(1, StrLen(chars)), 1)
            
        fullSavePath := targetDir "\" randStr ".png"
        
        ; 6. The PowerShell Bridge: Silently rip the image from RAM and save it
        psCommand := "powershell.exe -STA -NoProfile -WindowStyle Hidden -Command `"Add-Type -AssemblyName System.Windows.Forms; if ($img = [System.Windows.Forms.Clipboard]::GetImage()) { $img.Save('" fullSavePath "', [System.Drawing.Imaging.ImageFormat]::Png) }`""
        RunWait(psCommand, , "Hide")
        
        ; 7. Verification & Cleanup
        if FileExist(fullSavePath) {
            Notify("Capture Saved", "Image routed to Synced folder.`n" randStr ".png")
        } else {
            Notify("Capture Failed", "Clipboard did not contain valid image data.")
        }
        
        ; Aggressively terminate ShareX if it was used
        if (mode = "Scrolling") {
            RunWait("taskkill /F /IM ShareX.exe", , "Hide")
        }
        
    } else {
        ; Handle timeouts or cancellations
        if (mode = "Scrolling") {
            RunWait("taskkill /F /IM ShareX.exe", , "Hide")
            Notify("Capture Canceled", "Scrolling capture timed out.")
        } else if (mode = "Region") {
            Notify("Capture Canceled", "Snipping tool closed without selection.")
        }
    }
}

KillShareX() {
    RunWait("taskkill /F /IM ShareX.exe", , "Hide")
    Notify("ShareX Killed", "Memory manually freed.")
}