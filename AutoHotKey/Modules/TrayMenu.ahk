; ==============================================================================
; MODULE: CUSTOM TRAY MENU COMMAND CENTER
; ==============================================================================

BuildTrayMenu() {
    ; 1. Nuke the default AutoHotkey menu
    A_TrayMenu.Delete() 

    ; 2. Add Quick-Edit shortcuts to your most used modules
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
    
    TraySetIcon("imageres.dll", 174) 
}

; ------------------------------------------------------------------------------
; Menu Callback Functions
; ------------------------------------------------------------------------------
ToggleHotCorners(ItemName, ItemPos, MyMenu) {
    global HotCornersEnabled
    HotCornersEnabled := !HotCornersEnabled
    
    ; Dynamically rename the menu item so you know its current state
    if (HotCornersEnabled) {
        MyMenu.Rename(ItemName, "🟢 Hot Corners: ON")
    } else {
        MyMenu.Rename(ItemName, "🔴 Hot Corners: OFF")
    }
}

; ------------------------------------------------------------------------------
; Search Engine Menu (Triggered via Flow Launcher Leader Key)
; ------------------------------------------------------------------------------
ShowSearchEngineMenu() {
    SearchMenu := Menu()
    
    SearchMenu.Add("&G. Google", (*) => FlowSearch("g"))
    SearchMenu.Add("&A. Gemini", (*) => FlowSearch("gem"))
    SearchMenu.Add("D&u. DuckDuckGo", (*) => FlowSearch("duckduckgo"))
    SearchMenu.Add("&W. Wikipedia", (*) => FlowSearch("wiki"))
    SearchMenu.Add() 
    SearchMenu.Add("&H. GitHub", (*) => FlowSearch("gh"))
    SearchMenu.Add("G&i. GitHub Gist", (*) => FlowSearch("gist"))
    SearchMenu.Add("S&v. SVG Repo", (*) => FlowSearch("svg"))
    SearchMenu.Add() 
    SearchMenu.Add("&Y. YouTube", (*) => FlowSearch("yt"))
    SearchMenu.Add("&R. Reddit", (*) => FlowSearch("re"))
    SearchMenu.Add("&J. JustWatch", (*) => FlowSearch("jw"))
    SearchMenu.Add() 
    SearchMenu.Add("&M. Google Maps", (*) => FlowSearch("maps"))
    SearchMenu.Add("&D. Google Drive", (*) => FlowSearch("gd"))
    SearchMenu.Add("&E. Gmail", (*) => FlowSearch("gm"))
    SearchMenu.Add("&I. Google Images", (*) => FlowSearch("gi"))
    SearchMenu.Add("&T. Google Translate", (*) => FlowSearch("translate"))
    SearchMenu.Add("S&c. Google Scholar", (*) => FlowSearch("sc"))
    
    SearchMenu.Show()
}