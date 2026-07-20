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
            WinSetAlwaysOnTop(1, hwnd)
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
    if !IsSet(PWAVault)
        PWAVault := Map()
        
    savedTitleMode := A_TitleMatchMode
    savedHiddenMode := A_DetectHiddenWindows 
    SetTitleMatchMode(1) 
    searchString := appName . " ahk_class Chrome_WidgetWin_1"
    DetectHiddenWindows(true) 
    
    targetHwnd := 0
    
    ; SMART CHECK: Is this a raw web link from the Interceptor, or a local hotkey shortcut?
    isWebLink := RegExMatch(url, "^(https?://|www\.)")
    
    if (PWAVault.Has(appName) && WinExist("ahk_id " . PWAVault[appName])) {
        targetHwnd := PWAVault[appName]
        WinSetExStyle("-0x80", targetHwnd)
        WinShow(targetHwnd)
        DllCall("ShowWindow", "Ptr", targetHwnd, "Int", 9) ; SW_RESTORE
        WinActivate(targetHwnd)
        Notify("Media Resumed", appName " ready.")
        
        ; THE FIX: Only force navigation if we intercepted a new movie link!
        if (isWebLink) {
            Run(browser ' --app="' url '"') 
        }
    }
    else {
        if (foundHwnd := WinExist(searchString)) {
            targetHwnd := foundHwnd
            WinSetExStyle("-0x80", targetHwnd)
            WinShow(targetHwnd)
            DllCall("ShowWindow", "Ptr", targetHwnd, "Int", 9)
            WinActivate(targetHwnd)
            Notify("Media Recovered", appName " found in background.")
            
            if (isWebLink) {
                Run(browser ' --app="' url '"') 
            }
        }
        else {
            oldActive := WinActive("A")
            
            ; THE FIX: If it's a web link, force PWA mode. If it's a hotkey shortcut, run normally.
            if (isWebLink) {
                Run(browser ' --app="' url '" --start-maximized')
            } else {
                Run(browser ' ' url ' --start-maximized')
            }
            
            ; Dynamically wait for a completely NEW window to take focus
            Loop 60 {
                Sleep(100)
                active := WinActive("ahk_class Chrome_WidgetWin_1")
                if (active && active != oldActive) {
                    targetHwnd := active
                    break
                }
            }
            
            if (!targetHwnd) {
                Notify("Launch Error", appName " took too long.", true)
                SetTitleMatchMode(savedTitleMode)
                DetectHiddenWindows(savedHiddenMode)
                return
            }
        }
        
        PWAVault[appName] := targetHwnd
    }
    
    if (targetHwnd) {
        Sleep(200) ; Give the PWA frame a fraction of a second to render
        if (IsSet(hVDA) && hVDA) {
            MoveAndGoToDesktop(targetHwnd, targetDesktop)
        }
    }
    
    SetTitleMatchMode(savedTitleMode)
    DetectHiddenWindows(savedHiddenMode)
}

; ------------------------------------------------------------------------------
; PWA Auto-Interceptor (Media Only)
; ------------------------------------------------------------------------------
GroupAdd("MediaPWAs", "Crunchyroll - Vivaldi")
GroupAdd("MediaPWAs", "JioHotstar - Vivaldi")
GroupAdd("MediaPWAs", "Netflix - Vivaldi")
GroupAdd("MediaPWAs", "Prime Video - Vivaldi")
GroupAdd("MediaPWAs", "Spotify - Vivaldi")
GroupAdd("MediaPWAs", "YouTube - Vivaldi")

global PwaBlacklist := Map() 
global PrivateHwnds := Map() ; Permanent memory for Private Window IDs

; ------------------------------------------------------------------------------
; THE FIX: OS-Level Shell Hook (Tracks Private Windows automatically)
; ------------------------------------------------------------------------------
DllCall("RegisterShellHookWindow", "Ptr", A_ScriptHwnd)
OnMessage(DllCall("RegisterWindowMessage", "Str", "SHELLHOOK"), TrackPrivateWindows)

; Catch any private windows that are currently open on their Start Page
for hwnd in WinGetList("ahk_exe vivaldi.exe") {
    try {
        if InStr(WinGetTitle(hwnd), "Private") || InStr(WinGetTitle(hwnd), "Incognito")
            PrivateHwnds[hwnd] := true
    }
}

TrackPrivateWindows(wParam, lParam, msg, hwnd) {
    ; wParam 1 = Window Created | wParam 6 = Window Title Redrawn
    if (wParam == 1 || wParam == 6) {
        try {
            title := WinGetTitle("ahk_id " lParam)
            if InStr(title, "Private") || InStr(title, "Incognito") {
                global PrivateHwnds
                PrivateHwnds[lParam] := true ; Tag this unique window ID permanently
            }
        }
    }
}

SetTimer(CatchAndEject, 400)

CatchAndEject() {
    if (activeHwnd := WinActive("ahk_group MediaPWAs")) {
        global PWAVault, PwaBlacklist, PrivateHwnds
        
        ; 0. Exempt tracked Private Windows instantly
        if (IsSet(PrivateHwnds) && PrivateHwnds.Has(activeHwnd))
            return
            
        ; 1. Abort instantly if this window is in the Blacklist
        if (IsSet(PwaBlacklist) && PwaBlacklist.Has(activeHwnd))
            return
            
        ; 2. Abort if this window is safely tracked in the Vault
        if IsSet(PWAVault) {
            for app, vaultHwnd in PWAVault {
                if (activeHwnd == vaultHwnd)
                    return
            }
        }

        SetTimer(CatchAndEject, 0)
        Sleep(800) 
        
        ; Make sure the user didn't Alt+Tab away while we waited
        if !WinActive("ahk_id " . activeHwnd) {
            SetTimer(CatchAndEject, 400)
            return
        }
        
        SavedClip := A_Clipboard
        TargetURL := ""
        
        Loop 3 {
            A_Clipboard := ""
            Send("!{Space}") 
            Sleep(50)
            Send("{Esc}")    
            Sleep(50)
            Send("^l")
            Sleep(150)
            Send("^c")
            
            if ClipWait(0.8) {
                TargetURL := Trim(A_Clipboard, " `t`r`n")
                if InStr(TargetURL, "http") 
                    break
            }
        }
        
        ; If it failed, this is a PWA! Blacklist it and abort silently.
        if (TargetURL = "" || !InStr(TargetURL, "http")) {
            if !IsSet(PwaBlacklist)
                PwaBlacklist := Map()
            PwaBlacklist[activeHwnd] := true 
            
            A_Clipboard := SavedClip
            SetTimer(CatchAndEject, 400)
            return
        }
        
        Send("^w")
        A_Clipboard := SavedClip
        Sleep(400) 
        
        if RegExMatch(TargetURL, "^(https?://|www\.)[^\s]+") {
            static pwaMap := Map(
                "youtube.com", "YouTube", "youtu.be", "YouTube",
                "spotify.com", "Spotify", "netflix.com", "Netflix",
                "crunchyroll.com", "Crunchyroll", "hotstar.com", "Hotstar",
                "primevideo.com", "Prime Video"
            )
            
            targetTitle := ""
            for domain, title in pwaMap {
                if InStr(TargetURL, domain) {
                    targetTitle := title
                    break
                }
            }
            
            if (targetTitle != "") {
                LaunchWebAppToDesktop(TargetURL, targetTitle, 8)
            } else {
                Notify("Interceptor Failed", "Media domain not found in map.", true)
            }
        }
        
        Sleep(1000)
        SetTimer(CatchAndEject, 400)
    }
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