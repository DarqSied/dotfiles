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
        
        ; 1. Asynchronous Browser Polling 
        if (processName == "vivaldi.exe" || processName == "zen.exe") {
            windowTitle := WinGetTitle(hwnd)
            if (!InStr(windowTitle, "Private") && !InStr(windowTitle, "Incognito") && !InStr(windowTitle, "- Vivaldi") && !InStr(windowTitle, "- Zen Browser")) {
                SetTimer(AutoRouteWindow.Bind(hwnd), -50) 
                return
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
        
    ; Maps your exact app names to their installed Chromium IDs
    static AppIdMap := Map(
        "Crunchyroll", "--app-id=hjlhbeffadgkonmpnblkfmhckmocohah",
        "JioHotstar", "--app-id=bhelhlfglkopjlgmhjfejnkibbfgemcf",
        "Netflix", "--app-id=eppojlglocelodeimnohnlnionkobfln",
        "Prime Video", "--app-id=igpjbmoihojghddcmflmgeeadjkanlij",
        "Spotify", "--app-id=pjibgclleladliembfgfagdaldikeohf",
        "YouTube", "--app-id=agimnkijcaahngcdmfeangaknmldooml"
    )
        
    savedTitleMode := A_TitleMatchMode
    savedHiddenMode := A_DetectHiddenWindows 
    SetTitleMatchMode(1) 
    searchString := appName . " ahk_class Chrome_WidgetWin_1"
    DetectHiddenWindows(true) 
    
    targetHwnd := 0
    
    ; Determine if this is an intercepted video or just a standard hotkey launch
    isWebLink := RegExMatch(url, "^(https?://|www\.)")
    
    ; ==========================================================================
    ; SCENARIO 1: The App is already running in the background
    ; ==========================================================================
    if (PWAVault.Has(appName) && WinExist("ahk_id " . PWAVault[appName])) {
        targetHwnd := PWAVault[appName]
        
        if (isWebLink) {
            ; --- THE VISUAL PROMPT ---
            SwitchConfirm := MsgBox("A new link was intercepted.`n`nSwitch to this new video instead of the one currently playing in " appName "?", "Confirm Switch", "YesNo IconQuestion")
            
            if (SwitchConfirm == "No") {
                SetTitleMatchMode(savedTitleMode)
                DetectHiddenWindows(savedHiddenMode)
                return ; Abort the switch entirely
            }
        }
        
        ; Bring the existing PWA to the front
        WinSetExStyle("-0x80", targetHwnd)
        WinShow(targetHwnd)
        DllCall("ShowWindow", "Ptr", targetHwnd, "Int", 9) ; SW_RESTORE
        WinActivate(targetHwnd)
        WinWaitActive(targetHwnd, , 2)
        Notify("Media Resumed", appName " ready.")
        
        ; Force the window to navigate to the new video
        if (isWebLink) {
            Sleep(200) 
            InjectURL(url)
        }
    } 
    ; ==========================================================================
    ; SCENARIO 2: The App is NOT running (Cold Boot)
    ; ==========================================================================
    else {
        ; Check if it exists untracked
        if (foundHwnd := WinExist(searchString)) {
            targetHwnd := foundHwnd
            WinSetExStyle("-0x80", targetHwnd)
            WinShow(targetHwnd)
            DllCall("ShowWindow", "Ptr", targetHwnd, "Int", 9)
            WinActivate(targetHwnd)
            Notify("Media Recovered", appName " found in background.")
            
            if (isWebLink) {
                Sleep(200)
                InjectURL(url)
            }
        }
        else {
            oldActive := WinActive("A")
            
            ; Launch using the App ID to preserve the Vivaldi UI
            if (AppIdMap.Has(appName)) {
                Run(browser ' ' AppIdMap[appName] ' --start-maximized')
            } else {
                ; Fallback (Hotkeys pass the ID as the URL natively)
                Run(browser ' ' url ' --start-maximized')
            }
            
            ; Dynamically wait for the NEW window to take focus
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
            
            ; Wait for the UI to fully render, then push the specific video URL
            if (isWebLink && AppIdMap.Has(appName)) {
                Sleep(1200) ; Extra buffer for cold boots
                InjectURL(url)
            }
        }
        
        PWAVault[appName] := targetHwnd
    }
    
    ; 3. Desktop Routing Execution
    if (targetHwnd) {
        Sleep(200) 
        if (IsSet(hVDA) && hVDA) {
            MoveAndGoToDesktop(targetHwnd, targetDesktop)
        }
    }
    
    SetTitleMatchMode(savedTitleMode)
    DetectHiddenWindows(savedHiddenMode)
}

; ------------------------------------------------------------------------------
; Helper: Forces a chromeless/PWA window to navigate using keyboard injection
; ------------------------------------------------------------------------------
InjectURL(targetUrl) {
    savedClip := ClipboardAll()
    A_Clipboard := targetUrl
    
    if ClipWait(1) {
        ; Ctrl+L is the universal Chromium shortcut to focus the address bar. 
        ; Even if the bar is hidden, Chromium will catch this and prep for input!
        Send("^l")    
        Sleep(150)
        Send("^v")    ; Paste the new link
        Sleep(50)
        Send("{Enter}") ; Go!
    }
    A_Clipboard := savedClip
}

; ------------------------------------------------------------------------------
; PWA Auto-Interceptor & Router Initialization
; ------------------------------------------------------------------------------
global PwaBlacklist := Map() 
global PrivateHwnds := Map() ; Permanent memory for Private Window IDs

InitRouter() ; Execute the boot sequence

InitRouter() {
    global PWATitles, PWAVault, PrivateHwnds

    ; 1. Dynamically build the MediaPWAs group based on your Config array
    if IsSet(PWATitles) {
        for _, appName in PWATitles {
            GroupAdd("MediaPWAs", appName " - Vivaldi")
        }
    }
    
    ; 2. Register OS-Level Shell Hook for Private Windows
    DllCall("RegisterShellHookWindow", "Ptr", A_ScriptHwnd)
    OnMessage(DllCall("RegisterWindowMessage", "Str", "SHELLHOOK"), TrackPrivateWindows)
    
    ; 3. Catch any private windows already open on boot
    for hwnd in WinGetList("ahk_exe vivaldi.exe") {
        try {
            if InStr(WinGetTitle(hwnd), "Private") || InStr(WinGetTitle(hwnd), "Incognito")
                PrivateHwnds[hwnd] := true
        }
    }
    
    ; 4. Catch any PWAs already running (X-Ray Vision)
    prevDetectMode := A_DetectHiddenWindows
    DetectHiddenWindows(true) 
    
    if IsSet(PWAVault) && IsSet(PWATitles) {
        for hwnd in WinGetList("ahk_group MediaPWAs") {
            try {
                title := WinGetTitle(hwnd)
                for _, appName in PWATitles {
                    if InStr(title, appName) {
                        PWAVault[appName] := hwnd
                        break
                    }
                }
            }
        }
    }
    
    DetectHiddenWindows(prevDetectMode)
    
    ; 5. Engage the Interceptor Watchdog
    SetTimer(CatchAndEject, 400)
}

; ------------------------------------------------------------------------------
; OS-Level Shell Hook (Tracks Private Windows automatically)
; ------------------------------------------------------------------------------
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
        
        ; --- THE FIX: STRICT TITLE SANITY CHECK ---
        ; Prevents AI chats and Google searches from triggering the URL extraction
        windowTitle := WinGetTitle(activeHwnd)
        isValidMedia := false
        
        global PWATitles
        if IsSet(PWATitles) {
            for _, appName in PWATitles {
                if RegExMatch(windowTitle, "i)(^| - )" appName "($| - )") {
                    isValidMedia := true
                    break
                }
            }
        }
        
        if (!isValidMedia)
            return
            
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