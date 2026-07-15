; ==============================================================================
; [ MODULE: VIRTUAL DESKTOP & AUTO-ROUTING ENGINE ]
; ==============================================================================

; ------------------------------------------------------------------------------
; Universal Background Window Routing
; ------------------------------------------------------------------------------
AutoRouteWindow(hwnd) {
    global AppRoutingMap, PWATitles, LastDriveInsertTime, hVDA
    
    if (!hVDA or !WinExist(hwnd))
        return
    processName := "Unknown"
    try {
        processName := StrLower(WinGetProcessName(hwnd))
        windowClass := WinGetClass(hwnd)
        
        ; 1. Browser Polling Loop
        if (processName == "vivaldi.exe" || processName == "zen.exe") {
            Loop 25 { 
                if (!WinExist(hwnd)) {
                    return 
                }
                
                windowTitle := WinGetTitle(hwnd)
                
                if (InStr(windowTitle, "Private") || InStr(windowTitle, "Incognito")) {
                    break
                }
                Sleep(40) ; 25 loops * 40ms = 1000ms max wait for normal windows
            }
        }
        
        ; 2. Verify Survival
        if (!WinExist(hwnd))
            return
            
        windowTitle := WinGetTitle(hwnd)
        
        if (windowTitle = "Picture in picture" or windowTitle = "Picture-in-Picture") {
            WinSetAlwaysOnTop(-1, hwnd)
            DllCall(VDA_PATH "\PinWindow", "Ptr", hwnd)
            return 
        }

        targetDesk := -1 
        
        ; 3. PWA Check
        if (processName == "vivaldi.exe" || processName == "zen.exe") {
            for _, pwa in PWATitles {
                if (InStr(windowTitle, pwa)) {
                    return 
                }
            }
        }
        
        ; 4. Map Routing
        if (processName == "explorer.exe" and windowClass == "CabinetWClass") {
            ; A. Standard USB Drive insertion
            if (A_TickCount - LastDriveInsertTime < 5000) {
                targetDesk := 6 
                LastDriveInsertTime := 0 
            }
            ; B. Android Storage Share (MTP or Network)
            else if (InStr(windowTitle, "Internal shared storage") || InStr(windowTitle, "Himanshu's S25+")) {
                targetDesk := 6
            }
        }
        else if (AppRoutingMap.Has(processName)) {
            routeTarget := AppRoutingMap[processName]
            
            if (Type(routeTarget) == "Integer") {
                targetDesk := routeTarget
            } 
            else if (Type(routeTarget) == "Object") {
                targetDesk := routeTarget.desk 
                
                for keyword, deskIndex in routeTarget.titleRules {
                    if (InStr(windowTitle, keyword)) {
                        targetDesk := deskIndex
                        break
                    }
                }
            }
        }

        ; 5. Execution
        if (targetDesk != -1 and targetDesk != "SKIP") {
            DllCall(VDA_PATH "\MoveWindowToDesktopNumber", "Ptr", hwnd, "Int", targetDesk)
            DllCall(VDA_PATH "\GoToDesktopNumber", "Int", targetDesk)
        }
    } catch as err {
        ; THE BLACKBOX: Silently writes routing failures to debug.log 
        Logger("Routing Failed | App: " processName " | Error: " err.Message)   
    } 
    ; Try block silently swallows edge cases without halting the script or showing popups
}

; ------------------------------------------------------------------------------
; Smart Desktop Routing & Resurrector for PWAs
; ------------------------------------------------------------------------------
LaunchWebAppToDesktop(url, appName, targetDesktop, browser := "vivaldi.exe") {
    global hVDA, PWAVault
    
    savedTitleMode := A_TitleMatchMode
    savedHiddenMode := A_DetectHiddenWindows 
    
    SetTitleMatchMode(1) 
    searchString := appName . " ahk_class Chrome_WidgetWin_1"
    
    DetectHiddenWindows(true) 
    
    if (PWAVault.Has(appName) && WinExist("ahk_id " . PWAVault[appName])) {
        tH := PWAVault[appName]
        
        WinSetExStyle("-0x80", tH)
        WinShow(tH)
        DllCall("ShowWindow", "Ptr", tH, "Int", 9) ; SW_RESTORE
        WinActivate(tH)
        
        Notify("Media Resumed", appName " ready.")
    }
    else {
        targetHwnd := WinExist(searchString)
        
        if (targetHwnd) {
            WinSetExStyle("-0x80", targetHwnd)
            WinShow(targetHwnd)
            DllCall("ShowWindow", "Ptr", targetHwnd, "Int", 9)
            WinActivate(targetHwnd)
            Notify("Media Recovered", appName " found in background.")
        }
        else {
            Run(browser ' ' url ' --start-maximized')
            
            if not WinWait(searchString, , 6) {
                Notify("Launch Error", appName " took too long.", true)
                SetTitleMatchMode(savedTitleMode)
                DetectHiddenWindows(savedHiddenMode)
                return
            }
            targetHwnd := WinExist(searchString)
        }
        
        PWAVault[appName] := targetHwnd
        if (hVDA && targetHwnd) {
            MoveAndGoToDesktop(targetHwnd, targetDesktop)
        }
    }
    
    SetTitleMatchMode(savedTitleMode)
    DetectHiddenWindows(savedHiddenMode)
}

; ------------------------------------------------------------------------------
; Virtual Desktop Navigation Utilities (VDA)
; ------------------------------------------------------------------------------
GoToDesktop(target) {
    if (hVDA)
        DllCall(VDA_PATH "\GoToDesktopNumber", "Int", target)
}

GetCurrentDesktop() {
    return hVDA ? DllCall(VDA_PATH "\GetCurrentDesktopNumber", "Int") : 0
}

GetDesktopCount() {
    return hVDA ? DllCall(VDA_PATH "\GetDesktopCount", "Int") : 1
}

GoToNextDesktop() {
    total := GetDesktopCount()
    nextDesktop := GetCurrentDesktop() + 1
    GoToDesktop(nextDesktop >= total ? 0 : nextDesktop)
}

GoToPrevDesktop() {
    total := GetDesktopCount()
    prevDesktop := GetCurrentDesktop() - 1
    GoToDesktop(prevDesktop < 0 ? total - 1 : prevDesktop)
}

EnsureDesktops(targetCount) {
    currentCount := GetDesktopCount()
    if (currentCount < targetCount) {
        Loop (targetCount - currentCount) {
            Send("^#d")
            Sleep(500)
        }
        Sleep(150)
        GoToDesktop(0) 
    }
}

MoveActiveWindowToDesktop(target) {
    if (hVDA) {
        DllCall(VDA_PATH "\MoveWindowToDesktopNumber", "Ptr", WinExist("A"), "Int", target)
    }
}

MoveAndGoToDesktop(hwnd, targetDesk) {
    DllCall(VDA_PATH "\MoveWindowToDesktopNumber", "Ptr", hwnd, "Int", targetDesk)
    DllCall(VDA_PATH "\GoToDesktopNumber", "Int", targetDesk)
}

CarryActiveWindowToNextDesktop() {
    if (!hVDA) {
        return
    }
    activeHwnd := WinExist("A")
    total := GetDesktopCount()
    nextDesktop := GetCurrentDesktop() + 1
    targetDesk := (nextDesktop >= total) ? 0 : nextDesktop
    
    MoveAndGoToDesktop(activeHwnd, targetDesk)
}

CarryActiveWindowToPrevDesktop() {
    if (!hVDA) {
        return
    }
    activeHwnd := WinExist("A")
    total := GetDesktopCount()
    prevDesktop := GetCurrentDesktop() - 1
    targetDesk := (prevDesktop < 0) ? (total - 1) : prevDesktop
    
    MoveAndGoToDesktop(activeHwnd, targetDesk)
}

KillAllOnCurrentDesktop() {
    if (!hVDA) {
        return
    }
    currentDesk := GetCurrentDesktop()
    DetectHiddenWindows(false)
    
    for hwnd in WinGetList() {
        if (!(WinGetClass(hwnd) ~= "^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd)$")) {
            winDesk := DllCall(VDA_PATH "\GetWindowDesktopNumber", "Ptr", hwnd, "Int")
            if (winDesk == currentDesk) {
                WinClose(hwnd)
            }
        }
    }
}