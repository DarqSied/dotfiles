; ==============================================================================
; [ MODULE: CORE UTILITIES & HELPERS ]
; ==============================================================================

; ------------------------------------------------------------------------------
; SMART NOTIFIER (Global Control)
; ------------------------------------------------------------------------------
global HideStandardPopups := false 

Notify(title, message, isError := false) {
    global HideStandardPopups
    if (HideStandardPopups) { 
        return 
    }
    ToolTip(title ": " message, 10, 10)
    SetTimer () => ToolTip(), -2000 
}

; ------------------------------------------------------------------------------
; Silent Background Logger
; ------------------------------------------------------------------------------
Logger(Message, LogFile := "debug.log") {
    try {
        timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        FileAppend("[" timestamp "] " Message "`n", A_ScriptDir "\" LogFile)
    }
}

; ------------------------------------------------------------------------------
; Utility Macros
; ------------------------------------------------------------------------------
ToggleKeepAwake() {
    global IsAwake := !IsAwake
    SetTimer(KeepAwakeJiggle, IsAwake ? 300000 : 0)
    Notify("System Awake", IsAwake ? "Your PC will not go to sleep." : "Normal sleep schedule restored.")
}

KeepAwakeJiggle() => Send("{F15}")

GetLeaderInput() {
    ih := InputHook("L1 T2") 
    ih.Start()
    ih.Wait()
    return ih.Input
}

PasteAsPlain() {
    savedClip := ClipboardAll() 
    A_Clipboard := A_Clipboard  
    
    if ClipWait(1, 1) {
        Send("^v")
        Sleep(50) 
        A_Clipboard := savedClip 
    }
}

; ------------------------------------------------------------------------------
; App Launching & Flow Launcher
; ------------------------------------------------------------------------------
LaunchApp(appName, exePath) {
    BlockInput("On")
    prevDetect := A_DetectHiddenWindows
    DetectHiddenWindows(true)

    if not WinExist(appName) {
        Run(exePath)
        if not WinWait(appName, , 3) {
            DetectHiddenWindows(prevDetect)
            BlockInput("Off")
            return
        }
    }
    WinActivate(appName)
    WinWaitActive(appName, , 2)   
    WinSetAlwaysOnTop(-1, "A")
    
    DetectHiddenWindows(prevDetect)
    BlockInput("Off") 
}

FlowSearch(actionKeyword) {
    Send("{Blind}{LWin}") 
    if WinWaitActive("ahk_exe Flow.Launcher.exe", , 2) {
        Send("^a")       
        Sleep(30)        
        Send("{Text}" actionKeyword " ")
    } else {
        Notify("Flow Launcher Error", "Window failed to activate in time.", true)
    }
}

; ------------------------------------------------------------------------------
; Hot Corners Logic
; ------------------------------------------------------------------------------
global hMouseHook := 0
global LastCorner := "None"
global CornerTolerance := 5
global HotCornersEnabled := true

InstallMouseHook() {
    global hMouseHook
    if (hMouseHook)
        return

    ; WH_MOUSE_LL = 14. Bypasses AHK and registers directly into the Windows input stream.
    hMouseHook := DllCall("SetWindowsHookEx", 
        "Int", 14, 
        "Ptr", CallbackCreate(MouseHookProc, "Fast"), 
        "Ptr", DllCall("GetModuleHandle", "UInt", 0, "Ptr"), 
        "UInt", 0, 
        "Ptr")
}

MouseHookProc(nCode, wParam, lParam) {
    global LastCorner, CornerTolerance
    
    if (!HotCornersEnabled) {
        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
    }

    if (nCode >= 0 && wParam == 0x0200) {
        
        mouseX := NumGet(lParam, 0, "Int")
        mouseY := NumGet(lParam, 4, "Int")
        
        isTopLeft     := (mouseX <= CornerTolerance) && (mouseY <= CornerTolerance)
        isTopRight    := (mouseX >= A_ScreenWidth - 1 - CornerTolerance) && (mouseY <= CornerTolerance)
        isBottomLeft  := (mouseX <= CornerTolerance) && (mouseY >= A_ScreenHeight - 1 - CornerTolerance)
        isBottomRight := (mouseX >= A_ScreenWidth - 1 - CornerTolerance) && (mouseY >= A_ScreenHeight - 1 - CornerTolerance)
        
        currentCorner := isTopLeft ? "TopLeft" : isTopRight ? "TopRight" : isBottomLeft ? "BottomLeft" : isBottomRight ? "BottomRight" : "None"
        
        if (currentCorner != LastCorner) {
            
            ; ==============================================================================
            ; THE SHIELD: Only check for fullscreen IF a corner was just hit.
            ; ==============================================================================
            if (currentCorner != "None") {
                try {
                    WinGetPos(&winX, &winY, &winW, &winH, "A") ; Get active window size
                    
                    ; If the window covers the entire monitor (or slightly bleeds over like some borderless games)
                    if (winX <= 0 && winY <= 0 && winW >= A_ScreenWidth && winH >= A_ScreenHeight) {
                        LastCorner := currentCorner ; Register the corner so it doesn't spam, but DO NOT fire the action
                        return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
                    }
                }
            }
            
            LastCorner := currentCorner 
            
            ; --- HOT CORNER TRIGGERS ---
            if (currentCorner == "TopLeft")
                Send("^{Esc}")                      
            else if (currentCorner == "TopRight")
                Send("{LWin down}a{LWin up}")       
        }
    }
    
    return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
}

; ------------------------------------------------------------------------------
; Cross-Device Auto-Sorter (Syncthing)
; ------------------------------------------------------------------------------
SortSyncthingFiles() {
    syncDir := "C:\Users\himan\Downloads\Synced" 
    
    if not DirExist(syncDir) {
        return
    }
    
    Loop Files, syncDir "\*.*" {
        ext := StrLower(A_LoopFileExt)
        if (ext = "pdf") {
            try FileMove(A_LoopFilePath, "C:\Users\himan\Downloads\Phone Link\" A_LoopFileName)
        } else if (ext ~= "^(jpg|png)$") {
            try FileMove(A_LoopFilePath, "C:\Users\himan\Downloads\" A_LoopFileName)
        }
    }
}

; ------------------------------------------------------------------------------
; Current Screenshots folder Access
; ------------------------------------------------------------------------------
OpenMonthlyScreenshots(*) {
    currentMonth := FormatTime(, "yyyy-MM")
    targetDir := "C:\Users\himan\Downloads\Synced\Screenshots\" currentMonth
    
    if DirExist(targetDir) {
        Run('explore "' targetDir '"')
    } else {
        ; Assuming your Notify() function is globally accessible via Utilities.ahk
        Notify("Directory Missing", "No screenshots folder exists for " currentMonth " yet.")
    }
}

; ------------------------------------------------------------------------------
; Search Engine Menu
; ------------------------------------------------------------------------------
ShowSearchEngineMenu() {
    SearchMenu := Menu()
    
    ; --- General & AI ---
    SearchMenu.Add("&G. Google", (*) => FlowSearch("g"))
    SearchMenu.Add("&A. Gemini", (*) => FlowSearch("gem"))
    SearchMenu.Add("D&u. DuckDuckGo", (*) => FlowSearch("duckduckgo"))
    SearchMenu.Add("&W. Wikipedia", (*) => FlowSearch("wiki"))
    SearchMenu.Add() ; Separator
    
    ; --- Dev & Design ---
    SearchMenu.Add("&H. GitHub", (*) => FlowSearch("gh"))
    SearchMenu.Add("G&i. GitHub Gist", (*) => FlowSearch("gist"))
    SearchMenu.Add("S&v. SVG Repo", (*) => FlowSearch("svg"))
    SearchMenu.Add() ; Separator
    
    ; --- Media & Community ---
    SearchMenu.Add("&Y. YouTube", (*) => FlowSearch("yt"))
    SearchMenu.Add("&R. Reddit", (*) => FlowSearch("re"))
    SearchMenu.Add("&J. JustWatch", (*) => FlowSearch("jw"))
    SearchMenu.Add() ; Separator
    
    ; --- Google Suite ---
    SearchMenu.Add("&M. Google Maps", (*) => FlowSearch("maps"))
    SearchMenu.Add("&D. Google Drive", (*) => FlowSearch("gd"))
    SearchMenu.Add("&E. Gmail", (*) => FlowSearch("gm")) ; E for Email
    SearchMenu.Add("&I. Google Images", (*) => FlowSearch("gi"))
    SearchMenu.Add("&T. Google Translate", (*) => FlowSearch("translate"))
    SearchMenu.Add("S&c. Google Scholar", (*) => FlowSearch("sc"))
    
    ; Show the menu at the current mouse cursor position
    SearchMenu.Show()
}