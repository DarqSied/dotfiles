; ==============================================================================
; [ MODULE: WINDOW MANAGER & LAYOUT LOGIC ]
; ==============================================================================

; ------------------------------------------------------------------------------
; Layout Controls & States
; ------------------------------------------------------------------------------
ToggleGhostMode() {
    activeHwnd := WinExist("A")
    if !activeHwnd
        return
        
    if (WinGetTransparent(activeHwnd) = "") {
        WinSetTransparent(150, activeHwnd)
        WinSetExStyle("+0x20", activeHwnd) 
    } else {
        WinSetTransparent("Off", activeHwnd)
        WinSetExStyle("-0x20", activeHwnd)
    }
}

ActivateFocusMode() {
    activeHwnd := WinExist("A")
    if !activeHwnd
        return

    for hwnd in WinGetList() {
        if (hwnd != activeHwnd && !(WinGetClass(hwnd) ~= "^(Progman|WorkerW|Shell_TrayWnd)$")) {
            try WinMinimize(hwnd)
        }
    }
}

ToggleAlwaysOnTop() => WinSetAlwaysOnTop(-1, "A") 

CenterActiveWindow() {
    activeHwnd := WinExist("A")
    if !activeHwnd
        return
        
    MonitorGetWorkArea(, &Left, &Top, &Right, &Bottom)
    monitorWidth := Right - Left
    monitorHeight := Bottom - Top
    
    targetWidth := Integer(monitorWidth * 0.60)
    targetHeight := Integer(monitorHeight * 0.85)
    targetX := Left + Integer((monitorWidth - targetWidth) / 2)
    targetY := Top + Integer((monitorHeight - targetHeight) / 2)
    
    WinRestore(activeHwnd)
    WinMove(targetX, targetY, targetWidth, targetHeight, activeHwnd)
}

; ------------------------------------------------------------------------------
; Native Z-Order Stack Navigation
; ------------------------------------------------------------------------------
PushWindowDownStack() {
    activeHwnd := WinExist("A")
    if (activeHwnd) {
        WinMoveBottom(activeHwnd)
    }
}

PullWindowUpStack() {
    prevDetect := A_DetectHiddenWindows
    DetectHiddenWindows(false) 
    
    activeHwnd := WinExist("A")
    hwnds := WinGetList()
    
    Loop hwnds.Length {
        i := hwnds.Length - A_Index + 1
        hwnd := hwnds[i]
        
        if (hwnd != activeHwnd && !(WinGetClass(hwnd) ~= "^(Progman|WorkerW|Shell_TrayWnd)$")) {
            WinActivate(hwnd)
            break
        }
    }
    
    DetectHiddenWindows(prevDetect)
}

; ------------------------------------------------------------------------------
; XMonad-Style True Scratchpads
; ------------------------------------------------------------------------------
ToggleScratchpad(appPath, winTitle) {
    prevDetect := A_DetectHiddenWindows
    DetectHiddenWindows(true) 

    if WinExist(winTitle) {
        if WinActive(winTitle) {
            WinHide(winTitle) 
            Send("!{Esc}") 
        } else {
            WinShow(winTitle)
            WinActivate(winTitle)
        }
    } else {
        Run(appPath)
        if WinWait(winTitle, , 3) {
            WinSetAlwaysOnTop(-1, "A")
        }
    }
    DetectHiddenWindows(prevDetect)
}

; ------------------------------------------------------------------------------
; Global System Work Area Override & Smart Maximize
; ------------------------------------------------------------------------------
SetDockSpace(dockPosition := "Top", dockSizePixels := 50) {
    MonitorGet(1, &Left, &Top, &Right, &Bottom)
    
    if (dockPosition = "Top") {
        Top := Top + dockSizePixels
    } else if (dockPosition = "Bottom") {
        Bottom := Bottom - dockSizePixels
    } else if (dockPosition = "Left") {
        Left := Left + dockSizePixels
    } else if (dockPosition = "Right") {
        Right := Right - dockSizePixels
    }
    
    rect := Buffer(16, 0)
    NumPut("Int", Left,   rect, 0)
    NumPut("Int", Top,    rect, 4)
    NumPut("Int", Right,  rect, 8)
    NumPut("Int", Bottom, rect, 12)
    
    DllCall("SystemParametersInfo", "UInt", 0x002F, "UInt", 0, "Ptr", rect, "UInt", 0x0003)
}

SmartMaximize(dockHeight := 60) {
    activeHwnd := WinExist("A")
    
    if (WinGetMinMax(activeHwnd) == 1) {
        WinRestore(activeHwnd)
        Sleep(50) 
    }
    
    MonitorGet(1, &Left, &Top, &Right, &Bottom)
    
    screenWidth := Right - Left
    screenHeight := Bottom - Top
    
    WinMove(Left, Top + dockHeight, screenWidth, screenHeight - dockHeight, activeHwnd)
}