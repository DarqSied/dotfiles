; ==============================================================================
; [ MODULE: KEYBINDINGS & LEADER KEYS ]
; ==============================================================================

; ------------------------------------------------------------------------------
; [ HOTKEYS: INSTANT ACTIONS & WINDOW/DESKTOP MANAGEMENT ]
; ------------------------------------------------------------------------------
; --- Window & Workspace Destruction ---
#q::                                                                              ; Win+Q: Close Current App
{
    Send("{Blind}{vkE8}")
    Send("!{F4}")
}
#+q::KillAllOnCurrentDesktop()                                                    ; Win+Shift+Q: Kill Entire Workspace

; --- Terminals & Command Line ---
#Enter::Run("wt.exe")                                                             ; Win+Enter: Launch Normal Terminal
#+Enter::Run("*RunAs wt.exe")                                                     ; Win+Shift+Enter: Admin Terminal

; --- Web Browsers ---
#b::Run('"C:\Users\himan\AppData\Local\Vivaldi\Application\vivaldi.exe"')         ; Win+B: Vivaldi (Primary)
#+b::Run('"C:\Users\himan\AppData\Local\Zen Browser\zen.exe"')                    ; Win+Shift+B: Zen (Secondary)
#!b::Run('"C:\Users\himan\AppData\Local\Zen Browser\private_browsing.exe"')       ; Win+Alt+B: Zen Private

; --- Utilities & OS Toggles ---
#c::LaunchApp("Calculator", "calc.exe")                                           ; Win+C: Calculator
#w::LaunchApp("Clock", "ms-clock:")                                               ; Win+W: Clock/Stopwatch
#+v::PasteAsPlain()                                                               ; Win+Shift+V: Paste plain text
#+a::ToggleKeepAwake()                                                            ; Win+Shift+A: Toggle Keep-Awake
#^x::ComObject("Shell.Application").ShutdownWindows()                             ; Win+Ctrl+X: Shutdown Menu
#/::ShowCheatSheet()                                                              ; Win+/: Toggle Dynamic Cheatsheet

; --- Virtual Desktop Navigation (Base) ---
<#1::GoToDesktop(0)                                         ; Win+1 to 9: Jump to Desktop 1-9
<#2::GoToDesktop(1)
<#3::GoToDesktop(2)
<#4::GoToDesktop(3)
<#5::GoToDesktop(4)
<#6::GoToDesktop(5)
<#7::GoToDesktop(6)
<#8::GoToDesktop(7)
<#9::GoToDesktop(8)
^#Right::GoToNextDesktop()                                 ; Ctrl+Win+Right: Pan right one desktop
^#Left::GoToPrevDesktop()                                  ; Ctrl+Win+Left: Pan left one desktop

; --- Window Routing (Shift = Escalate) ---
+<#1::MoveActiveWindowToDesktop(0)                         ; Win+Shift+1 to 9: Move window to Desktop 1-9
+<#2::MoveActiveWindowToDesktop(1)
+<#3::MoveActiveWindowToDesktop(2)
+<#4::MoveActiveWindowToDesktop(3)
+<#5::MoveActiveWindowToDesktop(4)
+<#6::MoveActiveWindowToDesktop(5)
+<#7::MoveActiveWindowToDesktop(6)
+<#8::MoveActiveWindowToDesktop(7)
+<#9::MoveActiveWindowToDesktop(8)
^+#Right::CarryActiveWindowToNextDesktop()                 ; Ctrl+Shift+Win+Right: Carry window right
^+#Left::CarryActiveWindowToPrevDesktop()                  ; Ctrl+Shift+Win+Left: Carry window left
#+h::Send("#+{Left}")                                      ; Win+Shift+H: Send to left monitor
#+l::Send("#+{Right}")                                     ; Win+Shift+L: Send to right monitor

; --- Layout Controls & States ---
#Space::WinMaximize("A")                                   ; Win+Space: Monocle layout
#t::WinRestore("A")                                        ; Win+T: Sink/tile a floating window
#+t::CenterActiveWindow()                                  ; Win+Shift+T: Shrink and center window
#+f::ActivateFocusMode()                                   ; Win+Shift+F: Minimize all but active window

; --- Z-Order & Visibility States ---
#Up::PushWindowDownStack()                                 ; Win+Up: Focus next window down stack
#Down::PullWindowUpStack()                                 ; Win+Down: Focus prev window up stack
#p::ToggleAlwaysOnTop()                                    ; Win+P: Toggle Always-on-Top
#+g::ToggleGhostMode()                                     ; Win+Shift+G: Semi-transparent & click-through

; --- Desktop Creation & Deletion (System Level) ---
#^n::Send("#^d")                                           ; Win+Ctrl+N: Create new virtual desktop
#^q::Send("#^{F4}")                                        ; Win+Ctrl+Q: Delete current virtual desktop

; --- Mouse & Window controls ---
; Win+Left Click: Move Window
#LButton::
{
    CoordMode("Mouse", "Screen") 
    MouseGetPos(,, &targetWin)
    if (WinGetMinMax(targetWin) = 1) {
        WinRestore(targetWin)
        Sleep(50)
    }
    WinActivate(targetWin)
    MouseGetPos(&startX, &startY)
    WinGetPos(&startWinX, &startWinY,,, targetWin)
    while GetKeyState("LButton", "P") {
        MouseGetPos(&currentX, &currentY)
        DllCall("SetWindowPos", "Ptr", targetWin, "Ptr", 0, 
                "Int", startWinX + (currentX - startX), 
                "Int", startWinY + (currentY - startY), 
                "Int", 0, "Int", 0, "UInt", 0x5)
        Sleep(5) 
    }
}

; Win+Right Click: Resize Window
#RButton::
{
    CoordMode("Mouse", "Screen") 
    MouseGetPos(,, &targetWin)
    if (WinGetMinMax(targetWin) = 1) {
        WinRestore(targetWin)
        Sleep(50)
    }
    WinActivate(targetWin)
    MouseGetPos(&startX, &startY)
    WinGetPos(,, &startWinW, &startWinH, targetWin)
    while GetKeyState("RButton", "P") {
        MouseGetPos(&currentX, &currentY)
        newW := Max(150, startWinW + (currentX - startX))
        newH := Max(150, startWinH + (currentY - startY))
        DllCall("SetWindowPos", "Ptr", targetWin, "Ptr", 0, 
                "Int", 0, "Int", 0, 
                "Int", newW, "Int", newH, "UInt", 0x6)
        Sleep(5) 
    }
}

; ------------------------------------------------------------------------------
; [ QUICK DIRECTORY ACCESS ]
; ------------------------------------------------------------------------------
#!d::Run("shell:Downloads")                           ; Win + Alt + D -> Open Downloads Folder
#!f::Run('explore "C:\Users\himan\Downloads\Synced"') ; Win + Alt + F -> Open Root Syncthing Folder
#!a::Run('explore "' A_ScriptDir '"')                 ; Win + Alt + A -> Open AutoHotkey Script Directory

#!s::                                                 ; Win + Alt + S -> Open Current Month's Screenshots
{
    currentMonth := FormatTime(, "yyyy-MM")
    targetDir := "C:\Users\himan\Downloads\Synced\Screenshots\" currentMonth
    
    if DirExist(targetDir) {
        Run('explore "' targetDir '"')
    } else {
        Notify("Directory Missing", "No screenshots folder exists for " currentMonth " yet.")
    }
}

; ------------------------------------------------------------------------------
; [ HYBRID SCREENSHOT ENGINE TRIGGERS ]
; ------------------------------------------------------------------------------
$^PrintScreen::PerformCapture("Region")       ; Ctrl + PrintScreen -> Native Region
$PrintScreen::PerformCapture("FullScreen")    ; PrintScreen -> Native Full Screen
$!PrintScreen::PerformCapture("Window")       ; Alt + PrintScreen -> Native Window
$^!PrintScreen::PerformCapture("Scrolling")   ; Ctrl + Alt + PrintScreen -> ShareX Scrolling
#+PrintScreen::KillShareX()                   ; Win + Shift + PrintScreen -> Force Kill ShareX

; ------------------------------------------------------------------------------
; [ LEADER KEY 1: APP LAUNCHER (WIN + A) ]
; ------------------------------------------------------------------------------
#a:: {
    switch GetLeaderInput() {
        case "f": Run('"C:\Users\himan\Desktop\Files\foobar2000\foobar2000.exe"')        ; F: foobar2000
        case "c": LaunchWebAppToDesktop("--app-id=hjlhbeffadgkonmpnblkfmhckmocohah", "Crunchyroll - Watch Popular Anime", 8) ; C: Crunchyroll
        case "j": LaunchWebAppToDesktop("--app-id=bhelhlfglkopjlgmhjfejnkibbfgemcf", "JioHotstar", 8)                        ; J: JioHotstar
        case "n": LaunchWebAppToDesktop("--app-id=eppojlglocelodeimnohnlnionkobfln", "Netflix", 8)                           ; N: Netflix
        case "p": LaunchWebAppToDesktop("--app-id=igpjbmoihojghddcmflmgeeadjkanlij", "Prime Video", 8)                       ; P: Prime Video
        case "s": LaunchWebAppToDesktop("--app-id=pjibgclleladliembfgfagdaldikeohf", "Spotify", 8)                           ; S: Spotify
        case "y": LaunchWebAppToDesktop("--app-id=agimnkijcaahngcdmfeangaknmldooml", "YouTube", 8)                           ; Y: YouTube
        case "v": LaunchWebAppToDesktop("https://pass.proton.me/", "Proton Pass", 6)     ; V: Proton Pass Web Vault
        case "l": LaunchWebAppToDesktop("https://app.simplelogin.io/dashboard/", "SimpleLogin", 6) ; L: SimpleLogin
        case "r": LaunchWebAppToDesktop("https://app.raindrop.io/", "Raindrop.io", 6)    ; R: Raindrop.io
        case "w": Run("whatsapp:")                                                       ; W: WhatsApp
    }
}

; ------------------------------------------------------------------------------
; [ LEADER KEY 2: SCRATCHPADS (WIN + X) ]
; ------------------------------------------------------------------------------
#x:: {
    switch GetLeaderInput() {
        case "s": ToggleScratchpad("taskmgr.exe", "ahk_exe Taskmgr.exe")                                ; S: SysMon
        case "m": ToggleScratchpad("sndvol.exe", "ahk_exe sndvol.exe")                                  ; M: Mixer
        case "d": ToggleScratchpad("explorer.exe shell:Downloads", "Downloads ahk_class CabinetWClass") ; D: Downloads
    }
}

; ------------------------------------------------------------------------------
; [ LEADER KEY 3: SYSTEM TWEAKS & UTILITIES (WIN + S) ]
; ------------------------------------------------------------------------------
$#s:: {
    Send("{Blind}{vkE8}")
    KeyWait("LWin")
    KeyWait("RWin")
    
    switch GetLeaderInput() {
        case "r": Reload()                                                                                  ; R: Reload AHK
        case "e": Run('"' EnvGet("LOCALAPPDATA") '\Programs\VSCodium\VSCodium.exe" "' A_ScriptDir '"')      ; E: Edit Script Workspace
        case "t": ToggleTaskbar()                                                                           ; T: Toggle Taskbar
        case "b": ToggleAllTitleBars()                                                                      ; B: Toggle Borders
        case "m": SmartMaximize(30)                                                                         ; M: Maximize active window perfectly
    }
}

; ------------------------------------------------------------------------------
; [ LEADER KEY 4: FLOW LAUNCHER PLUGINS (WIN + F) ]
; ------------------------------------------------------------------------------
#f:: {
    switch GetLeaderInput() {
        case "k": FlowSearch("kill")         ; K: Process Killer
        case "u": FlowSearch("up")           ; U: AppUpgrader
        case "s": FlowSearch(">")            ; S: Shell
        case "p": FlowSearch("pm")           ; P: Plugins Manager
        case "x": FlowSearch("uni")          ; X: Uninstaller+
        case "w": FlowSearch("ww")           ; W: Window Walker
        case "b": FlowSearch("b")            ; B: Browser Bookmarks
        case "g": FlowSearch("g")            ; G: Web Searches
        case "y": FlowSearch("pn")           ; Y: Playnite
        case "a": FlowSearch("al")           ; A: AniList
        case "d": FlowSearch("d")            ; D: Dictionary
        case "c": FlowSearch("dc")           ; C: Date Calculator
    }
}

; ------------------------------------------------------------------------------
; [ LEADER KEY 5: THE LOCAL BRIDGE (WIN + Z) ]
; ------------------------------------------------------------------------------
#z:: {
    switch GetLeaderInput() {
        case "p": Run("ms-phone:")                                                     ; P: Phone Link Dashboard
        case "c":                                                                      ; C: Open Copied Link
            static pwaMap := Map(
                "youtube.com", "YouTube", "youtu.be", "YouTube",
                "spotify.com", "Spotify", "netflix.com", "Netflix",
                "crunchyroll.com", "Crunchyroll", "hotstar.com", "Hotstar",
                "primevideo.com", "Prime Video", "pass.proton.me", "Proton Pass",
                "app.simplelogin.io", "SimpleLogin", "app.raindrop.io", "Raindrop.io"
            )
            clipText := Trim(A_Clipboard)
            if RegExMatch(clipText, "^(https?://|www\.)[^\s]+") {
                isPWA := false
                targetTitle := ""
                for domain, title in pwaMap {
                    if (InStr(clipText, domain)) {
                        isPWA := true
                        targetTitle := title
                        break 
                    }
                }
                if (isPWA) {
                    LaunchWebAppToDesktop(clipText, targetTitle, 8)
                    Notify(targetTitle " Launched", "Sent to Desktop 9")
                } else {
                    Run(clipText)
                    Notify("Link Launched", "Opened standard URL.")
                }
            } else {
                Notify("Launch Failed", "No valid link in the clipboard.", true)
            }
        case "f": Run("explorer.exe C:\Users\himan\Downloads\Synced")               ; F: Syncthing Folder
        case "s": Run("http://127.0.0.1:8384/")                                     ; S: Syncthing Web GUI
        case "t":                                                                   ; T: Syncthing Status Ping
            if ProcessExist("syncthing.exe") {
                Notify("Syncthing Status", "🟢 Running in the background.")
            } else {
                Notify("Syncthing Status", "🔴 NOT Running.")
            }
        case "n":                                                                   ; N: Quick Sync Note
            savedNote := InputBox("Type note for phone:", "Local Sync", "w400 h100")
            if (savedNote.Result == "OK" && savedNote.Value != "") {
                timestamp := FormatTime(, "dd-MM-yyyy h:mm tt")
                FileAppend("[" timestamp "] " savedNote.Value "`n", "C:\Users\himan\Downloads\Synced\QuickNotes.txt")
                Notify("Synced", "Note sent to Syncthing folder.")
            }
            
        case "h":                                                                   ; H: Highlight to Sync
            savedClip := ClipboardAll() 
            A_Clipboard := ""           
            Send("^c")                  
            if ClipWait(1) {            
                timestamp := FormatTime(, "dd-MM-yyyy h:mm tt")
                FileAppend("[" timestamp "] " A_Clipboard "`n`n", "C:\Users\himan\Downloads\Synced\QuickNotes.txt")
                Notify("Clipped", "Highlighted text synced to phone.")
            }
            A_Clipboard := savedClip    
    }
}