; ==============================================================================
; [ MODULE: CORE ENGINE ] - INITIALIZATION, HOOKS & SYSTEM STATES
; ==============================================================================

Global FocusHookProc := 0
Global hWinEventHook := 0

; ------------------------------------------------------------------------------
; Initialization & Core Setup
; ------------------------------------------------------------------------------
Initialize() {
    global hVDA, VDA_PATH, TargetDesktopCount, FocusHookProc, hWinEventHook
    
    ; 1. Force Dark Mode for Native Menus BEFORE building the Tray Menu
    try {
        hTheme := DllCall("GetModuleHandle", "Str", "uxtheme", "Ptr")
        SetAppMode := DllCall("GetProcAddress", "Ptr", hTheme, "Ptr", 135, "Ptr")
        FlushMenu  := DllCall("GetProcAddress", "Ptr", hTheme, "Ptr", 136, "Ptr")
        DllCall(SetAppMode, "Int", 2)
        DllCall(FlushMenu)
    }

    BuildTrayMenu()
    InstallMouseHook()
    SendMode("Input")
    SetWorkingDir(A_ScriptDir)
    OnExit(RestoreTaskbar)
    
    if (A_PtrSize = 4) {
        MsgBox("Error: Please run this script with the 64-bit version of AutoHotkey to support the VDA DLL.")
        ExitApp()
    }

    if !FileExist(VDA_PATH) {
        MsgBox("Error: VirtualDesktopAccessor.dll not found.`n`nPlease download it and place it in the same folder as this script.")
        ExitApp()
    }
    
    hVDA := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")
    
    ApplyTaskbarProcesses()
    
    SetTimer(EnforceTaskbarVisibility, 500)
    SetTimer(SortSyncthingFiles, 10000)

    DllCall("RegisterShellHookWindow", "Ptr", A_ScriptHwnd)
    OnMessage(DllCall("RegisterWindowMessage", "Str", "SHELLHOOK"), OnWindowCreated)
    OnMessage(0x0219, OnDeviceArrival)
    
    ; 2. Register Kernel-Level Foreground Focus Tracker
    if (!FocusHookProc) {
        FocusHookProc := CallbackCreate(OnForegroundChange, "F")
        hWinEventHook := DllCall("SetWinEventHook"
            , "UInt", 0x0003, "UInt", 0x0003
            , "Ptr", 0, "Ptr", FocusHookProc
            , "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")
    }
    
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
; System Styling & Hooks (Taskbar, Titlebars)
; ------------------------------------------------------------------------------
ToggleTaskbar() {
    global TaskbarShouldBeHidden := !TaskbarShouldBeHidden
    ApplyTaskbarProcesses()
}

SetTaskbarAppBarState(autoHide := true) {
    ; ABM_SETSTATE (0x0A): 1 = ABS_AUTOHIDE (collapses reserved space), 0 = ABS_ALWAYSONTOP
    abd := Buffer(48, 0)
    NumPut("UInt", 48, abd, 0)
    if (hTray := DllCall("FindWindow", "Str", "Shell_TrayWnd", "Ptr", 0, "Ptr"))
        NumPut("Ptr", hTray, abd, A_PtrSize)
    NumPut("UInt", autoHide ? 1 : 0, abd, 40)
    DllCall("Shell32\SHAppBarMessage", "UInt", 0x0000000A, "Ptr", abd)
}

ApplyTaskbarProcesses() {
    global TaskbarShouldBeHidden
    
    if (TaskbarShouldBeHidden) {
        if ProcessExist("translucenttb.exe")
            ProcessClose("translucenttb.exe")
        SetTaskbarAppBarState(true)
    } else {
        SetTaskbarAppBarState(false)
        if !ProcessExist("translucenttb.exe") {
            try Run('cmd.exe /c start "" "ttb.exe"', "", "Hide")
        }
    }
    
    EnforceTaskbarVisibility()
}

EnforceTaskbarVisibility() {
    global TaskbarShouldBeHidden
    
    prevDetectTaskbar := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    
    ; Explicitly target explorer.exe so YASB's tray hook is never hit by mistake
    for hwnd in WinGetList("ahk_class Shell_TrayWnd ahk_exe explorer.exe") {
        try {
            if (TaskbarShouldBeHidden)
                WinHide("ahk_id " hwnd)
            else
                WinShow("ahk_id " hwnd)
        }
    }
    
    for hwnd in WinGetList("ahk_class Shell_SecondaryTrayWnd ahk_exe explorer.exe") {
        try {
            if (TaskbarShouldBeHidden)
                WinHide("ahk_id " hwnd)
            else
                WinShow("ahk_id " hwnd)
        }
    }
    
    DetectHiddenWindows(prevDetectTaskbar)
}

RestoreTaskbar(ExitReason, ExitCode) {
    global hMouseHook, hWinEventHook
    
    if (hMouseHook)
        DllCall("UnhookWindowsHookEx", "Ptr", hMouseHook)
    if (hWinEventHook)
        DllCall("UnhookWinEvent", "Ptr", hWinEventHook)
        
    SetTaskbarAppBarState(false)
    
    prevDetect := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    for hwnd in WinGetList("ahk_class Shell_TrayWnd ahk_exe explorer.exe")
        try WinShow("ahk_id " hwnd)
    for hwnd in WinGetList("ahk_class Shell_SecondaryTrayWnd ahk_exe explorer.exe")
        try WinShow("ahk_id " hwnd)
    DetectHiddenWindows(prevDetect)
    
    if !ProcessExist("translucenttb.exe") {
        try Run('cmd.exe /c start "" "ttb.exe"', "", "Hide")
    }
}

ToggleAllTitleBars() {
    global GlobalTitleBarsHidden := !GlobalTitleBarsHidden
    ApplyGlobalTitleBarState(true)
}

ApplyGlobalTitleBarState(forceToggle := false) {
    for hwnd in WinGetList() {
        EnforceTitleBarState(hwnd, forceToggle)
    }
}

OnWindowCreated(wParam, lParam, *) {
    if (wParam = 1) {
        SetTimer(EnforceTitleBarState.Bind(lParam, false), -50)
        SetTimer(AutoRouteWindow.Bind(lParam), -100)
    }
}

EnforceTitleBarState(hwnd, forceToggle := false) {
    global GlobalTitleBarsHidden
    if (!WinExist(hwnd))
        return
    if (!GlobalTitleBarsHidden && !forceToggle)
        return

    try {
        exe := StrLower(WinGetProcessName(hwnd))
        if (exe == "yasb.exe" || exe == "yasb_themes.exe")
            return

        if (WinGetTitle(hwnd) = "" || WinGetClass(hwnd) ~= "^(Progman|WorkerW|Shell_TrayWnd|CabinetWClass|Chrome_WidgetWin_1|Notepad|ApplicationFrameWindow)$")
            return
         
        WinSetStyle(GlobalTitleBarsHidden ? "-0xC40000" : "+0xC40000", hwnd)
        ForceWindowRecalculation(hwnd)
    }
}

ForceWindowRecalculation(hwnd) => DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0027)

; ------------------------------------------------------------------------------
; GLOBAL FOCUS TRACKER (KERNEL-LEVEL WINEVENT HOOK)
; ------------------------------------------------------------------------------
OnForegroundChange(hHook, event, hwnd, idObject, idChild, idEventThread, dwmsEventTime) {
    try {
        activeClass := WinGetClass("ahk_id " hwnd)
        
        if (activeClass = "Shell_TrayWnd") {
            SetTimer(ForceDesktopFocus, -50)
            return
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
}

; ------------------------------------------------------------------------------
; HOT CORNERS (KERNEL-LEVEL MOUSE HOOK)
; ------------------------------------------------------------------------------
InstallMouseHook() {
    global hMouseHook
    if (hMouseHook)
        return

    hMouseHook := DllCall("SetWindowsHookEx", 
        "Int", 14, 
        "Ptr", CallbackCreate(MouseHookProc, "Fast"), 
        "Ptr", DllCall("GetModuleHandle", "UInt", 0, "Ptr"), 
        "UInt", 0, "Ptr")
}

MouseHookProc(nCode, wParam, lParam) {
    global LastCorner, CornerTolerance, HotCornersEnabled
    
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
            if (currentCorner != "None") {
                try {
                    activeHwnd := WinExist("A")
                    activeClass := WinGetClass(activeHwnd)
                    
                    if (!(activeClass ~= "^(Progman|WorkerW)$")) {
                        WinGetPos(&winX, &winY, &winW, &winH, activeHwnd)
                        if (winX <= 0 && winY <= 0 && winW >= A_ScreenWidth && winH >= A_ScreenHeight) {
                            LastCorner := currentCorner
                            return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
                        }
                    }
                }
            }
            LastCorner := currentCorner 
            
            ; Dispatch keystrokes asynchronously so the low-level mouse hook never blocks
            if (currentCorner == "TopLeft")
                SetTimer(() => Send("^{Esc}"), -10)
            else if (currentCorner == "TopRight")
                SetTimer(() => Send("#a"), -10)
        }
    }
    return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
}