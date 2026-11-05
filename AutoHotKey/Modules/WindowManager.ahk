; ==============================================================================
; [ MODULE: WINDOW MANAGER & LAYOUT LOGIC ]
; ==============================================================================

Global FloatedWindows := Map()
Global TrackedPopups := Map()
Global LastWindowList := ""
Global LastDesk := -1
Global TiledOrder := []
Global CurrentTiledCount := 0

; START THE WATCHDOG
SetTimer(ProcessDynamicLayout, 250)

TrackDynamicLayouts(params*) {
    SetTimer(ProcessDynamicLayout, -50)
}

; --- THE WINDOW FILTER (Crash-Proof) ---
IsTileable(hwnd) {
    global FloatedWindows
    if !IsSet(FloatedWindows)
        FloatedWindows := Map()
        
    if FloatedWindows.Has(hwnd)
        return false

    windowId := "ahk_id " . hwnd

    try {
        if (!WinExist(windowId) || !DllCall("IsWindowVisible", "Ptr", hwnd))
            return false
            
        minMax := WinGetMinMax(windowId)
        if (minMax == -1)
            return false
            
        ; Ignore true fullscreen apps (F11 / games), but keep tracking natively maximized windows (minMax == 1)
        if (minMax != 1) {
            WinGetPos(&winX, &winY, &winW, &winH, windowId)
            Loop MonitorGetCount() {
                MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)
                if (winW >= (mRight - mLeft - 2) && winH >= (mBottom - mTop - 2))
                    return false
            }
        }

        title := WinGetTitle(windowId)
        if (title == "" || title ~= "^(Program Manager|Shut Down Windows|Picture in picture|Picture-in-Picture|WhatsApp|Phone Link|Calculator)$")
            return false
        if (title ~= "i)(CAT_Comprehensive_Plan|CAT_QA_Formula_Notebook)")
            return false

        exStyle := WinGetExStyle(windowId)
        if (exStyle & 0x00000080) ; WS_EX_TOOLWINDOW
            return false

        style := WinGetStyle(windowId)
        if !(style & 0x10000) ; WS_MAXIMIZEBOX
            return false
            
        cloaked := 0
        DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "Int", 14, "Int*", &cloaked, "Int", 4)
        if (cloaked)
            return false
            
        winClass := WinGetClass(windowId)
        if (winClass ~= "^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd|NotifyIconOverflowWindow|Windows\.UI\.Core\.CoreWindow|TopLevelWindowForOverflowXamlIsland|XamlExplorerHostIslandWindow|PopupHost|#32770)$")
            return false
            
        exe := WinGetProcessName(windowId)
        if (exe ~= "i)^(yasb\.exe|yasb_themes\.exe|ShareX\.exe|ScreenClippingHost\.exe|SnippingTool\.exe|PowerToys\.exe|AutoHotkey.*\.exe|StartMenuExperienceHost\.exe|SearchHost\.exe|ShellExperienceHost\.exe|sihost\.exe|CalculatorApp\.exe|calc\.exe|Taskmgr\.exe|sndvol\.exe|Flow\.Launcher\.exe|TextInputHost\.exe)$")
            return false

        return true
    } catch {
        ; If the window closed mid-check, safely ignore it
        return false
    }
}

; --- THE MASTER ROUTER ---
ProcessDynamicLayout(params*) {
    global hVDA, VDA_PATH, LastWindowList, LastDesk, FloatedWindows, TiledOrder, CurrentTiledCount
    
    if !IsSet(TiledOrder) || Type(TiledOrder) !== "Array"
        TiledOrder := []
    if !IsSet(FloatedWindows)
        FloatedWindows := Map()
        
    ; Keep PiP and WhatsApp popups pinned across virtual desktops
    ManagePopups()
        
    currentDesk := 0
    try {
        if (hVDA && VDA_PATH)
            currentDesk := DllCall(VDA_PATH "\GetCurrentDesktopNumber", "Int")
    } catch {
        currentDesk := 0
    }
    
    ; 1. Gather all currently valid, tileable windows
    validSet := Map()
    currentTileable := []
    
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
        validSet[hwnd] := true
        currentTileable.Push(hwnd)
    }
    
    ; 2. Stabilize the array (Prevents focus-jumping)
    newTiledOrder := []
    
    for hwnd in TiledOrder {
        if validSet.Has(hwnd) {
            newTiledOrder.Push(hwnd)
            validSet.Delete(hwnd) 
        }
    }
    
    for hwnd in currentTileable {
        if validSet.Has(hwnd) {
            newTiledOrder.Push(hwnd) 
        }
    }
    
    TiledOrder := newTiledOrder
    
    ; 3. Enforce the 4-window limit
    if (TiledOrder.Length > 4) {
        while (TiledOrder.Length > 4) {
            excessHwnd := TiledOrder.Pop()
            if (!FloatedWindows.Has(excessHwnd)) {
                FloatedWindows[excessHwnd] := true
                ToolTip("Max 4 Tiled. Window auto-floated.")
                SetTimer(() => ToolTip(), -1500)
            }
        }
    }
    
    validWindows := TiledOrder
    
    ; 4. Check if layout actually needs updating
    currentList := ""
    for hwnd in validWindows {
        currentList .= hwnd . "|"
    }
    
    appCount := validWindows.Length
    CurrentTiledCount := appCount
    
    if (currentList == LastWindowList && currentDesk == LastDesk)
        return
        
    LastWindowList := currentList
    LastDesk := currentDesk

    if (appCount > 0) {
        ApplyMathLayout(validWindows, currentDesk, appCount)
    }
    
    WindowBorder.Update()
}

; --- THE GEOMETRY FILTER ---
ApplyMathLayout(windows, currentDesk, count) {
    ; Single-Window Mode: Native Maximize instead of geometry tiling
    if (count == 1) {
        hwnd := windows[1]
        windowId := "ahk_id " . hwnd
        if (!WinExist(windowId))
            return
            
        try {
            ; Restore default corner preference (square corners when maximized)
            cornerPref := Buffer(4, 0)
            NumPut("Int", 1, cornerPref, 0) ; DWMWCP_DONOTROUND
            DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", 33, "Ptr", cornerPref, "UInt", 4)
            
            if (WinGetMinMax(windowId) != 1)
                WinMaximize(windowId)
        }
        return
    }

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
    
    g := 10 ; GAP SIZE
    
    for index, hwnd in windows {
        windowId := "ahk_id " . hwnd 
        
        ; 1. THE PULSE CHECK: Skip if the window was closed in the last 250ms
        if (!WinExist(windowId))
            continue
            
        ; 2. THE SAFE RESTORE: Un-maximize when transitioning from 1 window to 2+ windows
        try {
            if (WinGetMinMax(windowId) == 1) {
                WinRestore(windowId)
                Sleep(60) 
            }
        } catch {
            continue
        }
            
        tX := Left, tY := Top, tW := W, tH := H
        
        if (count == 2) {
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
            rect := Buffer(16, 0)
            offX := 0, offY := 0, offW := 0, offH := 0
            
            if (DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 9, "Ptr", rect, "UInt", 16) == 0) {
                dx := NumGet(rect, 0, "Int")
                dy := NumGet(rect, 4, "Int")
                dw := NumGet(rect, 8, "Int") - dx
                dh := NumGet(rect, 12, "Int") - dy
                
                WinGetPos(&wx, &wy, &ww, &wh, windowId)
                
                offX := wx - dx
                offY := wy - dy
                offW := ww - dw
                offH := wh - dh
            }
            
            WinMove(tX + offX, tY + offY, tW + offW, tH + offH, windowId)
            
            cornerPref := Buffer(4, 0)
            if (tY <= 32) {
                NumPut("Int", 1, cornerPref, 0) ; DWMWCP_DONOTROUND
            } else {
                NumPut("Int", 2, cornerPref, 0) ; DWMWCP_ROUND
            }
            DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", 33, "Ptr", cornerPref, "UInt", 4)
            
        } catch {
        }
    }
}

; ------------------------------------------------------------------------------
; NATIVE WINDOW BORDER HIGHLIGHTER (EVENT HOOK OPTIMIZED)
; ------------------------------------------------------------------------------
class WindowBorder {
    static lastHwnd := 0
    static accentColor := 0x00FFFFFF
    static hookProc := 0
    
    static Init() {
        if (WindowBorder.hookProc)
            return
            
        WindowBorder.UpdateAccentColor()
        
        ; Register EVENT_SYSTEM_FOREGROUND (0x0003) Hook (For instant Alt+Tab)
        WindowBorder.hookProc := CallbackCreate(WindowBorder.OnForegroundChange, "F")
        DllCall("SetWinEventHook"
            , "UInt", 0x0003, "UInt", 0x0003 
            , "Ptr", 0
            , "Ptr", WindowBorder.hookProc
            , "UInt", 0, "UInt", 0, "UInt", 0)
            
        ; Continuously checks if the active window changed dimensions (e.g. went fullscreen)
        SetTimer(() => WindowBorder.Update(), 150)
            
        WindowBorder.Update()
    }

    static UpdateAccentColor() {
        WindowBorder.accentColor := 0x00FFFFFF ; White Border
    }
    
    static OnForegroundChange(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime) {
        WindowBorder.Update(hwnd)
    }
    
    static Update(hwnd := 0) {
        global CurrentTiledCount
        if (!hwnd)
            hwnd := WinExist("A")
            
        ; Fast check using the window count already maintained by ProcessDynamicLayout
        if (CurrentTiledCount < 2) {
            if (WindowBorder.lastHwnd && WinExist(WindowBorder.lastHwnd)) {
                try {
                    bufDefault := Buffer(4, 0)
                    NumPut("UInt", 0xFFFFFFFE, bufDefault, 0)
                    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", WindowBorder.lastHwnd, "UInt", 34, "Ptr", bufDefault, "UInt", 4)
                } catch {
                }
                WindowBorder.lastHwnd := 0
            }
            return
        }
            
        if (!hwnd || !WinExist(hwnd))
            return
            
        try {
            winClass := WinGetClass(hwnd)
            if (winClass ~= "^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd)$")
                return
                
            exe := StrLower(WinGetProcessName(hwnd))
            if (exe == "flow.launcher.exe" || exe == "yasb.exe" || exe == "yasb_themes.exe")
                return
                
            WinGetPos(&winX, &winY, &winW, &winH, hwnd)
            isFullScreen := false
            Loop MonitorGetCount() {
                MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)
                mW := mRight - mLeft
                mH := mBottom - mTop
                if (winW >= (mW - 2) && winH >= (mH - 2)) {
                    isFullScreen := true
                    break
                }
            }
            
            isMaximized := (WinGetMinMax(hwnd) == 1)
            shouldHaveBorder := !(isFullScreen || isMaximized)
        } catch {
            return
        }
        
        ; Clear the old window's border if focus changed to a new window
        if (WindowBorder.lastHwnd && WindowBorder.lastHwnd != hwnd) {
            try {
                bufDefault := Buffer(4, 0)
                NumPut("UInt", 0xFFFFFFFE, bufDefault, 0)
                DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", WindowBorder.lastHwnd, "UInt", 34, "Ptr", bufDefault, "UInt", 4)
            } catch {
            }
            WindowBorder.lastHwnd := 0 
        }
        
        ; Apply or remove border on the current window based on its fullscreen state
        try {
            if (shouldHaveBorder) {
                if (WindowBorder.lastHwnd != hwnd) { 
                    bufColor := Buffer(4, 0)
                    NumPut("UInt", WindowBorder.accentColor, bufColor, 0)
                    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", 34, "Ptr", bufColor, "UInt", 4)
                    WindowBorder.lastHwnd := hwnd
                }
            } else {
                if (WindowBorder.lastHwnd == hwnd) { 
                    bufDefault := Buffer(4, 0)
                    NumPut("UInt", 0xFFFFFFFE, bufDefault, 0)
                    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", 34, "Ptr", bufDefault, "UInt", 4)
                    WindowBorder.lastHwnd := 0
                }
            }
        } catch {
            WindowBorder.lastHwnd := 0
        }
    }
}

; ------------------------------------------------------------------------------
; "ORDERED OTHERWISE": PROMOTE ACTIVE WINDOW TO MASTER
; ------------------------------------------------------------------------------
PromoteToMaster() {
    global TiledOrder, LastWindowList
    activeHwnd := WinExist("A")
    if !activeHwnd
        return
        
    for index, hwnd in TiledOrder {
        if (hwnd == activeHwnd) {
            if (index == 1)
                return
                
            TiledOrder.RemoveAt(index)
            TiledOrder.InsertAt(1, activeHwnd)
            
            LastWindowList := ""
            ProcessDynamicLayout()
            return
        }
    }
}

; ------------------------------------------------------------------------------
; [ PART 2: MANUAL LAYOUT CONTROLS & OVERRIDES ]
; ------------------------------------------------------------------------------
ToggleFloatState() {
    global FloatedWindows, LastWindowList
    hwnd := WinExist("A")
    if (!hwnd)
        return
        
    if FloatedWindows.Has(hwnd) {
        FloatedWindows.Delete(hwnd)
        ToolTip("Grid Snap: ENABLED")
        SetTimer(() => ToolTip(), -1500)
    } else {
        FloatedWindows[hwnd] := true
        try {
            if (WinGetMinMax(hwnd) == 1) {
                WinRestore(hwnd)
                Sleep(40)
            }
            WinGetPos(&X, &Y, &W, &H, hwnd)
            WinMove(X + 50, Y + 50, W - 100, H - 100, hwnd)
        }
        ToolTip("Floating: UNHOOKED")
        SetTimer(() => ToolTip(), -1500)
    }
    
    LastWindowList := "" 
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
    
    try {
        WinRestore(activeHwnd)
        WinMove(targetX, targetY, targetWidth, targetHeight, activeHwnd)
    }
}

SmartMaximize(dockHeight := 32) {
    global FloatedWindows, LastWindowList
    activeHwnd := WinExist("A")
    if !activeHwnd
        return

    FloatedWindows[activeHwnd] := true 
    LastWindowList := ""
    
    try {
        if (WinGetMinMax(activeHwnd) == 1) {
            WinRestore(activeHwnd)
            Sleep(50) 
        }
        
        MonitorGet(1, &Left, &Top, &Right, &Bottom)
        screenWidth := Right - Left
        screenHeight := Bottom - Top
        
        WinMove(Left, Top + dockHeight, screenWidth, screenHeight - dockHeight, activeHwnd)
    }
}

ToggleGhostMode() {
    activeHwnd := WinExist("A")
    if !activeHwnd
        return
        
    try {
        if (WinGetTransparent(activeHwnd) = "") {
            WinSetTransparent(150, activeHwnd)
            WinSetExStyle("+0x20", activeHwnd) 
        } else {
            WinSetTransparent("Off", activeHwnd)
            WinSetExStyle("-0x20", activeHwnd)
        }
    }
}

ActivateFocusMode() {
    global TiledOrder
    activeHwnd := WinExist("A")
    if !activeHwnd
        return
        
    for hwnd in TiledOrder {
        if (hwnd != activeHwnd) {
            try WinMinimize("ahk_id " . hwnd)
        }
    }
}

ToggleAlwaysOnTop() => WinSetAlwaysOnTop(-1, "A") 

PushWindowDownStack() {
    activeHwnd := WinExist("A")
    if (activeHwnd) {
        try WinMoveBottom(activeHwnd)
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
        try {
            if (hwnd != activeHwnd && !(WinGetClass(hwnd) ~= "^(Progman|WorkerW|Shell_TrayWnd)$")) {
                WinActivate(hwnd)
                break
            }
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

; ------------------------------------------------------------------------------
; [ PART 3: PiP & POP-UP "FOLLOW ME" ENGINE ]
; ------------------------------------------------------------------------------
ManagePopups() {
    global hVDA, VDA_PATH, TrackedPopups
    
    if !IsSet(TrackedPopups)
        TrackedPopups := Map()
        
    for hwnd in WinGetList() {
        windowId := "ahk_id " . hwnd
        if (!WinExist(windowId))
            continue
            
        title := ""
        exe := ""
        try {
            title := WinGetTitle(windowId)
            exe := WinGetProcessName(windowId)
        } catch {
            continue
        }
        
        isFollowMe := false
        
        if (title == "Picture in picture" || title == "Picture-in-Picture")
            isFollowMe := true
            
        if (exe ~= "i)whatsapp\.exe" && title != "WhatsApp" && title != "")
            isFollowMe := true
            
        if (isFollowMe && !TrackedPopups.Has(hwnd)) {
            TrackedPopups[hwnd] := true
            try WinSetAlwaysOnTop(1, windowId)
            
            if (hVDA && VDA_PATH) {
                try DllCall(VDA_PATH "\PinWindow", "Ptr", hwnd)
            }
        }
    }
    
    for hwnd in TrackedPopups.Clone() {
        if (!WinExist("ahk_id " . hwnd)) {
            TrackedPopups.Delete(hwnd)
        } else if (hVDA && VDA_PATH) {
            try {
                currentDesk := DllCall(VDA_PATH "\GetCurrentDesktopNumber", "Int")
                winDesk := DllCall(VDA_PATH "\GetWindowDesktopNumber", "Ptr", hwnd, "Int")
                if (winDesk != -1 && winDesk != currentDesk) {
                    DllCall(VDA_PATH "\MoveWindowToDesktopNumber", "Ptr", hwnd, "Int", currentDesk)
                }
            }
        }
    }
}