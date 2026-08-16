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
    plainText := A_Clipboard
    A_Clipboard := ""
    A_Clipboard := plainText
    
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
; Cross-Device Auto-Sorter (Syncthing)
; ------------------------------------------------------------------------------
SortSyncthingFiles() {
    syncDir := PATH_SYNCTHING
    
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
    targetDir := PATH_SCREENSHOTS "\" currentMonth
    
    if DirExist(targetDir) {
        Run('explore "' targetDir '"')
    } else {
        Notify("Directory Missing", "No screenshots folder exists for " currentMonth " yet.")
    }
}