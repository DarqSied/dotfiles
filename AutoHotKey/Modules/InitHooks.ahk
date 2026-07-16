; ==============================================================================
; [ MODULE: CORE ENGINE ] - INITIALIZATION, HOOKS & SYSTEM STATES
; ==============================================================================

; ------------------------------------------------------------------------------
; Initialization & Core Setup
; ------------------------------------------------------------------------------
Initialize() {
    global hVDA, TargetDesktopCount, CornerInterval
    
    BuildTrayMenu()
    InstallMouseHook()
    SendMode("Input")
    SetWorkingDir(A_ScriptDir)
    OnExit(RestoreTaskbar)
    
    if (A_PtrSize = 4) {
        MsgBox("Error: Please run this script with the 64-bit version of AutoHotkey to support the VDA DLL.")
        ExitApp()
    }

    if not FileExist(VDA_PATH) {
        MsgBox("Error: VirtualDesktopAccessor.dll not found.`n`nPlease download it and place it in the same folder as this script.")
        ExitApp()
    }
    
    hVDA := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")
    WinWait(TASKBAR_WND, , 10) 
    Sleep(1000)
    
    try WinHide TASKBAR_WND
    try WinHide SECONDARY_TASKBAR_WND
    SetTimer(EnforceTaskbarVisibility, 500)
    SetTimer(SortSyncthingFiles, 10000)

    DllCall("RegisterShellHookWindow", "Ptr", A_ScriptHwnd)
    OnMessage(DllCall("RegisterWindowMessage", "Str", "SHELLHOOK"), OnWindowCreated)
    OnMessage(0x0219, OnDeviceArrival)
    
    EnsureDesktops(TargetDesktopCount)
    ApplyGlobalTitleBarState()
}

; ------------------------------------------------------------------------------
; Hardware Event Listener (USB/Drive Connections)
; ------------------------------------------------------------------------------
OnDeviceArrival(wParam, lParam, msg, hwnd) {
    global LastDriveInsertTime
    if (wParam = 0x8000) {
        LastDriveInsertTime := A_TickCount
    }
}

; ------------------------------------------------------------------------------
; Modernize UI & Force Dark Mode for Native Menus (AHK v2)
; ------------------------------------------------------------------------------
; 1. Get the memory handle for the uxtheme library
hTheme := DllCall("GetModuleHandle", "Str", "uxtheme", "Ptr")

; 2. Extract the specific memory pointers for the undocumented ordinals
SetAppMode := DllCall("GetProcAddress", "Ptr", hTheme, "Ptr", 135, "Ptr")
FlushMenu  := DllCall("GetProcAddress", "Ptr", hTheme, "Ptr", 136, "Ptr")

; 3. Execute the pointers
DllCall(SetAppMode, "Int", 2) ; 2 = Force Dark Mode
DllCall(FlushMenu)

; ------------------------------------------------------------------------------
; System Styling & Hooks (Taskbar, Titlebars)
; ------------------------------------------------------------------------------
ToggleTaskbar() {
    global TaskbarShouldBeHidden := !TaskbarShouldBeHidden
    EnforceTaskbarVisibility()
}

EnforceTaskbarVisibility() {
    global TaskbarShouldBeHidden, TASKBAR_WND, SECONDARY_TASKBAR_WND
    DetectHiddenWindows(true)
    
    if (TaskbarShouldBeHidden) {
        try WinHide(TASKBAR_WND)
        try WinHide(SECONDARY_TASKBAR_WND)
        if ProcessExist("translucenttb.exe") {
            ProcessClose("translucenttb.exe")
        }
    } else {
        try WinShow(TASKBAR_WND)
        try WinShow(SECONDARY_TASKBAR_WND)
        if !ProcessExist("translucenttb.exe") {
            try {
                Run('cmd.exe /c start "" "ttb.exe"', "", "Hide")
            } catch {
            }
        }
    }
}

RestoreTaskbar(ExitReason, ExitCode) {
    try WinShow(TASKBAR_WND)
    try WinShow(SECONDARY_TASKBAR_WND)
    if !ProcessExist("translucenttb.exe") {
        try Run('cmd.exe /c start "" "ttb.exe"', "", "Hide")
    }
}

ToggleAllTitleBars() {
    global GlobalTitleBarsHidden := !GlobalTitleBarsHidden
    ApplyGlobalTitleBarState()
}

ApplyGlobalTitleBarState() {
    for hwnd in WinGetList() {
        EnforceTitleBarState(hwnd)
    }
}

OnWindowCreated(wParam, lParam, *) {
    if (wParam = 1) {
        SetTimer(EnforceTitleBarState.Bind(lParam), -50)
        SetTimer(AutoRouteWindow.Bind(lParam), -100)
    }
}

EnforceTitleBarState(hwnd) {
    global GlobalTitleBarsHidden
    if (!GlobalTitleBarsHidden || !WinExist(hwnd))
        return

    try {
        if (WinGetTitle(hwnd) = "" || WinGetClass(hwnd) ~= "^(Progman|WorkerW|Shell_TrayWnd|CabinetWClass|Chrome_WidgetWin_1)$")
             return
         
        WinSetStyle(GlobalTitleBarsHidden ? "-0xC00000" : "+0xC00000", hwnd)
        ForceWindowRecalculation(hwnd)
    }
}

ForceWindowRecalculation(hwnd) => DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0027)


; ------------------------------------------------------------------------------
; GLOBAL FOCUS TRACKER (KERNEL-LEVEL WINEVENT HOOK)
; ------------------------------------------------------------------------------
; Shell Hooks are blind to custom docks (Tool Windows). This kernel hook tracks 
; literal foreground changes at the OS level, meaning nothing can hide from it.

Global FocusHookProc := CallbackCreate(OnForegroundChange, "F")

Global hWinEventHook := DllCall("SetWinEventHook"
    , "UInt", 0x0003, "UInt", 0x0003
    , "Ptr", 0, "Ptr", FocusHookProc
    , "UInt", 0, "UInt", 0, "UInt", 0)

OnForegroundChange(hHook, event, hwnd, idObject, idChild, idEventThread, dwmsEventTime) {
    try {
        activeExe := WinGetProcessName("ahk_id " hwnd)
        activeClass := WinGetClass("ahk_id " hwnd)
        
        if (activeExe = "Microsoft.CmdPal.UI.exe" || activeClass = "Shell_TrayWnd") {
            SetTimer(ForceDesktopFocus, -50) ; Asynchronous bounce
        }
    }
}

ForceDesktopFocus() {
    try {
        WinActivate("ahk_class WorkerW")
        ControlFocus("SysListView321", "ahk_class WorkerW")
    } catch {
        try {
            WinActivate("ahk_class Progman")
            ControlFocus("SysListView321", "ahk_class Progman")
        }
    }
    
    if (WinActive("ahk_exe Microsoft.CmdPal.UI.exe")) {
        Send("!{Esc}")
    }
}

; ------------------------------------------------------------------------------
; UWP Startup Sniper (Background Apps)
; ------------------------------------------------------------------------------
SnipeUWPApps() {
    ; Negative timers (-10) fire exactly once, asynchronously. 
    ; This ensures WinWait doesn't freeze your hotkeys while waiting for the apps to boot.
    SetTimer(HideWhatsApp, -10)
    SetTimer(HidePhoneLink, -10)
}

HideWhatsApp() {
    ; Wait up to 20 seconds for the app to appear
    if WinWait("WhatsApp",, 20) {
        Sleep(800) ; Wait for the XAML engine to replace the splash screen
        WinClose("WhatsApp") ; Dismiss to the system tray
    }
}

HidePhoneLink() {
    if WinWait("Phone Link",, 20) {
        Sleep(800)
        WinClose("Phone Link") 
    }
}

; Engage the sniper on engine startup
SnipeUWPApps()