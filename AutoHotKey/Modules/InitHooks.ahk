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
    } else {
        try WinShow(TASKBAR_WND)
        try WinShow(SECONDARY_TASKBAR_WND)
    }
}

RestoreTaskbar(ExitReason, ExitCode) {
    try WinShow(TASKBAR_WND)
    try WinShow(SECONDARY_TASKBAR_WND)
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
