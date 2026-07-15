; ==============================================================================
; MODULE: CUSTOM TRAY MENU COMMAND CENTER
; ==============================================================================

BuildTrayMenu() {
    ; 1. Nuke the default AutoHotkey menu
    A_TrayMenu.Delete() 

    ; 2. Add Quick-Edit shortcuts to your most used modules
    ; (Change the editor path if you don't use VS Code by default)
    A_TrayMenu.Add("⚙️ Edit Main Hub", (*) => Edit())
    A_TrayMenu.Add("⌨️ Edit Keybindings", (*) => Run("Code.exe " A_ScriptDir "\Modules\Keybindings.ahk"))
    A_TrayMenu.Add("🔤 Edit Hotstrings", (*) => Run("Code.exe " A_ScriptDir "\Modules\Hotstrings.ahk"))
    A_TrayMenu.Add("📝 Edit Cheatsheet", (*) => Run("Code.exe " A_ScriptDir "\Modules\Cheatsheet.ahk"))
    
    A_TrayMenu.Add() ; Separator line

    ; 3. Add Live Toggles
    A_TrayMenu.Add("🟢 Hot Corners: ON", ToggleHotCorners)
    
    A_TrayMenu.Add() ; Separator line

    ; 4. Add Quick Directories (Update path to match your screenshots folder)
    A_TrayMenu.Add("📸 Open Screenshots", OpenMonthlyScreenshots)
    
    A_TrayMenu.Add() ; Separator line

    ; 5. System Controls
    A_TrayMenu.Add("🔄 Reload Engine", (*) => Reload())
    A_TrayMenu.Add("❌ Exit Engine", (*) => ExitApp())
    
    ; Optional: Change the default green 'H' icon to something stealthy
    ; 174 = A sleek gear/settings icon from native Windows files
    TraySetIcon("imageres.dll", 174) 
}

; ------------------------------------------------------------------------------
; Menu Callback Functions
; ------------------------------------------------------------------------------
ToggleHotCorners(ItemName, ItemPos, MyMenu) {
    global HotCornersEnabled
    HotCornersEnabled := !HotCornersEnabled ; Flip the boolean
    
    ; Dynamically rename the menu item so you know its current state
    if (HotCornersEnabled) {
        MyMenu.Rename(ItemName, "🟢 Hot Corners: ON")
    } else {
        MyMenu.Rename(ItemName, "🔴 Hot Corners: OFF")
    }
}