; ==============================================================================
; [ MODULE: WINDOW MANAGER & LAYOUT LOGIC ]
; ==============================================================================

; ------------------------------------------------------------------------------
; [ PART 1: THE AUTO-TILING ENGINE (TWM) ]
; ------------------------------------------------------------------------------
Global FloatedWindows := Map()
Global LastWindowList := ""
Global LastDesk := -1

; START THE WATCHDOG: Runs continuously in the background (virtually 0% CPU).
SetTimer(ProcessDynamicLayout, 250)

; Shell hook now acts as an instant-trigger for fast-loading apps
TrackDynamicLayouts(params*) {
    SetTimer(ProcessDynamicLayout, -50)
}

; --- THE WINDOW FILTER ---
IsTileable(hwnd) {
    global FloatedWindows
    windowId := "ahk_id " . hwnd

    if (!WinExist(windowId) || !DllCall("IsWindowVisible", "Ptr", hwnd))
        return false
        
    if (WinGetMinMax(windowId) == -1)
        return false
        
    title := WinGetTitle(windowId)
    if (title == "" || title == "Program Manager" || title == "Shut Down Windows")
        return false
    
    if (title == "Picture in picture" || title == "Picture-in-Picture")
        return false

    if (title ~= "i)(CAT_Comprehensive_Plan|CAT_QA_Formula_Notebook)")
        return false
        
    if FloatedWindows.Has(hwnd)
        return false

    exStyle := WinGetExStyle(windowId)
    if (exStyle & 0x00000080) ; WS_EX_TOOLWINDOW
        return false

    style := WinGetStyle(windowId)
    if (style & 0x08000000) ; WS_DISABLED
        return false
        
    cloaked := 0
    DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "Int", 14, "Int*", &cloaked, "Int", 4)
    if (cloaked)
        return false
        
    class := WinGetClass(windowId)
    if (class ~= "^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd|NotifyIconOverflowWindow|Windows\.UI\.Core\.CoreWindow|TopLevelWindowForOverflowXamlIsland|XamlExplorerHostIslandWindow|PopupHost|#32770)$")
        return false
        
    exe := WinGetProcessName(windowId)
    if (exe ~= "i)^(ShareX\.exe|ScreenClippingHost\.exe|SnippingTool\.exe|PowerToys\.exe|AutoHotkey.*\.exe|StartMenuExperienceHost\.exe|SearchHost\.exe|ShellExperienceHost\.exe|sihost\.exe|CalculatorApp\.exe|calc\.exe|Taskmgr\.exe|sndvol\.exe|Flow\.Launcher\.exe|TextInputHost\.exe)$")
        return false
        
    title := WinGetTitle(windowId)
    if (title == "WhatsApp" || title == "Phone Link" || title == "Calculator")
        return false

    return true
}

; --- THE MASTER ROUTER ---
ProcessDynamicLayout(params*) {
    global hVDA, VDA_PATH, LastWindowList, LastDesk, FloatedWindows
    
    currentDesk := 0
    try {
        if (hVDA && VDA_PATH)
            currentDesk := DllCall(VDA_PATH "\GetCurrentDesktopNumber", "Int")
    } catch {
        currentDesk := 0
    }
    
    validWindows := []
    
    for hwnd in WinGetList() {
        if (!IsTileable(hwnd))
            continue
            
        if (hVDA && VDA_PATH) {
            try {
                winDesk := DllCall(VDA_PATH "\GetWindowDesktopNumber", "Ptr", hwnd, "Int")
                if (winDesk != -1 && winDesk != currentDesk)
                    continue
            } catch {
            }
        }
        validWindows.Push(hwnd)
    }
    
    if (validWindows.Length > 4) {
        while (validWindows.Length > 4) {
            excessHwnd := validWindows.RemoveAt(1)
            if (!FloatedWindows.Has(excessHwnd)) {
                FloatedWindows[excessHwnd] := true
                ToolTip("Max 4 Tiled. Window auto-floated.")
                SetTimer(() => ToolTip(), -1500)
            }
        }
        
        validWindows := []
        for hwnd in WinGetList() {
            if (!IsTileable(hwnd))
                continue
            if (hVDA && VDA_PATH) {
                try {
                    winDesk := DllCall(VDA_PATH "\GetWindowDesktopNumber", "Ptr", hwnd, "Int")
                    if (winDesk != -1 && winDesk != currentDesk)
                        continue
                } catch {
                }
            }
            validWindows.Push(hwnd)
        }
    }
    
    currentList := ""
    for hwnd in validWindows {
        currentList .= hwnd . "|"
    }
    
    appCount := validWindows.Length
    
    if (currentList == LastWindowList && currentDesk == LastDesk)
        return
        
    LastWindowList := currentList
    LastDesk := currentDesk

    if (appCount > 0) {
        ApplyMathLayout(validWindows, currentDesk, appCount)
    }
}

; --- THE GEOMETRY FILTER ---
ApplyMathLayout(windows, currentDesk, count) {
    Left := 0, Top := 0, Right := A_ScreenWidth, Bottom := A_ScreenHeight
    try {
        MonitorGetWorkArea(1, &Left, &Top, &Right, &Bottom)
    }
    
    W := Right - Left
    H := Bottom - Top
    if (W <= 0 || H <= 0) {
        W := A_ScreenWidth
        H := A_ScreenHeight
    }
    
    g := 5 ; GAP SIZE
    
    for index, hwnd in windows {
        windowId := "ahk_id " . hwnd 
        
        ; 1. THE PULSE CHECK: Skip if the window was closed in the last 250ms
        if (!WinExist(windowId))
            continue
            
        ; 2. THE SAFE RESTORE: Swallow errors if the window dies during the animation
        try {
            if (WinGetMinMax(windowId) == 1) {
                WinRestore(windowId)
                Sleep(60) 
            }
        } catch {
            continue
        }
            
        tX := Left, tY := Top, tW := W, tH := H
        
        if (count == 1) {
            tX += g, tY += g, tW -= (g * 2), tH -= (g * 2)
        } 
        else if (count == 2) {
            tW := (W // 2) - (g * 3 // 2), tH := H - (g * 2)
            tX := (index == 1) ? Left + g : Left + (W // 2) + (g // 2)
            tY := Top + g
        } 
        else if (count == 3) {
            if (currentDesk == 0 || currentDesk == 2) { 
                if (index == 1) { 
                    tX := Left + g, tY := Top + g
                    tW := W - (g * 2), tH := (H // 2) - (g * 3 // 2)
                } else { 
                    tY := Top + (H // 2) + (g // 2)
                    tW := (W // 2) - (g * 3 // 2), tH := (H // 2) - (g * 3 // 2)
                    tX := (index == 2) ? Left + g : Left + (W // 2) + (g // 2)
                }
            } 
            else if (currentDesk == 1) { 
                tW := (W // 3) - (g * 4 // 3), tH := H - (g * 2)
                tY := Top + g
                if (index == 1)
                    tX := Left + g
                else if (index == 2)
                    tX := Left + (W // 3) + (g // 2)
                else
                    tX := Left + (W * 2 // 3)
            } 
            else { 
                if (index == 1) {
                    tX := Left + g, tY := Top + g
                    tW := (W // 2) - (g * 3 // 2), tH := H - (g * 2)
                } else {
                    tX := Left + (W // 2) + (g // 2)
                    tW := (W // 2) - (g * 3 // 2), tH := (H // 2) - (g * 3 // 2)
                    tY := (index == 2) ? Top + g : Top + (H // 2) + (g // 2)
                }
            }
        } 
        else { 
            idx := (index > 4) ? 4 : index 
            tW := (W // 2) - (g * 3 // 2), tH := (H // 2) - (g * 3 // 2)
            tX := (idx == 1 || idx == 3) ? Left + g : Left + (W // 2) + (g // 2)
            tY := (idx == 1 || idx == 2) ? Top + g : Top + (H // 2) + (g // 2)
        }
        
        try {
            WinMove(tX, tY, tW, tH, windowId)
        } catch {
            ; 3. SAFE MOVE: Swallow errors if UAC/Admin blocks the move
        }
    }
}

; ------------------------------------------------------------------------------
; NATIVE WINDOW BORDER HIGHLIGHTER
; ------------------------------------------------------------------------------
class WindowBorder {
    static lastHwnd := 0
    static accentColor := 0x00F6823B
    
    static Init() {
        WindowBorder.UpdateAccentColor()
        SetTimer(() => WindowBorder.Update(), 100)
    }
    
    static UpdateAccentColor() {
        try {
            accentInt := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\DWM", "AccentColor")
            red   := accentInt & 0xFF
            green := (accentInt >> 8) & 0xFF
            blue  := (accentInt >> 16) & 0xFF
            WindowBorder.accentColor := (blue << 16) | (green << 8) | red
        } catch {
            WindowBorder.accentColor := 0x003B82F6
        }
    }
    
    static Update() {
        hwnd := WinExist("A")
        if (!hwnd || hwnd == WindowBorder.lastHwnd)
            return
            
        class := WinGetClass(hwnd)
        if (class ~= "^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd)$")
            return
            
        try {
            exe := StrLower(WinGetProcessName(hwnd))
            if (exe == "flow.launcher.exe")
                return
        } catch {
        }
        
        if (WindowBorder.lastHwnd && WinExist(WindowBorder.lastHwnd)) {
            try {
                bufDefault := Buffer(4, 0)
                NumPut("UInt", 0xFFFFFFFF, bufDefault, 0)
                DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", WindowBorder.lastHwnd, "UInt", 34, "Ptr", bufDefault, "UInt", 4)
            } catch {
            }
        }
        
        try {
            if (WinGetMinMax(hwnd) != 1) {
                bufColor := Buffer(4, 0)
                NumPut("UInt", WindowBorder.accentColor, bufColor, 0)
                DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", 34, "Ptr", bufColor, "UInt", 4)
                WindowBorder.lastHwnd := hwnd
            } else {
                WindowBorder.lastHwnd := 0
            }
        } catch {
            WindowBorder.lastHwnd := 0
        }
    }
}

; ------------------------------------------------------------------------------
; [ PART 2: MANUAL LAYOUT CONTROLS & OVERRIDES ]
; ------------------------------------------------------------------------------
ToggleFloatState() {
    global FloatedWindows
    hwnd := WinExist("A")
    if (!hwnd)
        return
        
    if FloatedWindows.Has(hwnd) {
        FloatedWindows.Delete(hwnd)
        ToolTip("Grid Snap: ENABLED")
        SetTimer(() => ToolTip(), -1500)
    } else {
        FloatedWindows[hwnd] := true
        WinGetPos(&X, &Y, &W, &H, hwnd)
        WinMove(X + 50, Y + 50, W - 100, H - 100, hwnd)
        ToolTip("Floating: UNHOOKED")
        SetTimer(() => ToolTip(), -1500)
    }
    
    global LastWindowList := "" 
    ProcessDynamicLayout()
}

CenterActiveWindow() {
    global FloatedWindows, LastWindowList
    activeHwnd := WinExist("A")
    if !activeHwnd
        return
        
    FloatedWindows[activeHwnd] := true 
    LastWindowList := ""
        
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

SmartMaximize(dockHeight := 60) {
    global FloatedWindows, LastWindowList
    activeHwnd := WinExist("A")
    if !activeHwnd
        return

    FloatedWindows[activeHwnd] := true 
    LastWindowList := ""
    
    if (WinGetMinMax(activeHwnd) == 1) {
        WinRestore(activeHwnd)
        Sleep(50) 
    }
    
    MonitorGet(1, &Left, &Top, &Right, &Bottom)
    
    screenWidth := Right - Left
    screenHeight := Bottom - Top
    
    WinMove(Left, Top + dockHeight, screenWidth, screenHeight - dockHeight, activeHwnd)
}

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