; ==============================================================================
; [ MODULE: CONFIGURATION AND SETUP ] - GLOBAL CONSTANTS & PATHS
; ==============================================================================

; --- VDA & System Variables ---
global VDA_PATH := A_ScriptDir "\VirtualDesktopAccessor.dll"
global hVDA := 0
global LastDriveInsertTime := 0
global TargetDesktopCount := 9
global TaskbarShouldBeHidden := true
global GlobalTitleBarsHidden := true
global IsAwake := false

; --- Window Classes ---
global TASKBAR_WND := "ahk_class Shell_TrayWnd"
global SECONDARY_TASKBAR_WND := "ahk_class Shell_SecondaryTrayWnd"

; --- Hot Corner Configurations ---
global CornerTolerance := 15
global CornerInterval := 100
global LastCorner := "None"
global HotCornersEnabled := true
global hMouseHook := 0

; --- PWA Exclusion List ---
global PWATitles := ["YouTube", "Netflix", "Crunchyroll", "Hotstar", "Prime Video", "Spotify"]

; --- GLOBAL PATHS (Change these if you move to a new PC) ---
global PATH_SYNCTHING   := "C:\Users\himan\Downloads\Synced"
global PATH_SCREENSHOTS := PATH_SYNCTHING "\Screenshots"
global PATH_QUICKNOTES  := PATH_SYNCTHING "\QuickNotes.txt"
global PATH_FOOBAR      := "C:\Users\himan\Desktop\Files\foobar2000\foobar2000.exe"
global PATH_SHAREX      := '"C:\Program Files\ShareX\ShareX.exe"'
global PATH_VIVALDI     := '"' EnvGet("LOCALAPPDATA") '\Vivaldi\Application\vivaldi.exe"'
global PATH_ZEN         := '"' EnvGet("LOCALAPPDATA") '\Zen Browser\zen.exe"'
global PATH_ZEN_PRIV    := '"' EnvGet("LOCALAPPDATA") '\Zen Browser\private_browsing.exe"'
global PATH_CAT_EXCEL   := A_Desktop "\CAT_Comprehensive_Plan.xlsx"
global PATH_CAT_FORMULA := A_Desktop "\CAT_QA_Formula_Notebook.docx"

; --- Smart Auto-Routing Dictionary ---
global AppRoutingMap := Map(
    "vscodium.exe", 1,
    "githubdesktop.exe", 1,
    "windowsterminal.exe", 1,
    "pwsh.exe", 1,
    "cmd.exe", 1,
    "sumatrapdf.exe", 1,
    "discord.exe", 2,
    "whatsapp.exe", 2,
    "applicationframehost.exe", {desk: "SKIP", titleRules: Map("WhatsApp", 2)},
    "steam.exe", 3,
    "riotclientux.exe", 3,
    "upc.exe", 3,
    "eadesktop.exe", 3,
    "playnite.desktopapp.exe", "SKIP",
    "playnite.fullscreenapp.exe", 3,
    "bmaac.exe", 3,
    "batmanak.exe", 3,
    "farcry6.exe", 3,
    "cs2.exe", 3,
    "csgo.exe", 3,
    "re8.exe", 3,
    "bfv.exe", 3,
    "among us.exe", 3,
    "leagueclientux.exe", 3,
    "league of legends.exe", 3,
    "valorant.exe", 3,
    "valorant-win64-shipping.exe", 3,
    "zen.exe", {desk: 4, titleRules: Map("Private", 6, "Incognito", 6)},
    "vivaldi.exe", {desk: 4, titleRules: Map("Private", 6, "Incognito", 6)},
    "deluge.exe", 7,
    "syncthing.exe", 7,
    "potplayer64.exe", 8,
    "foobar2000.exe", 8
)

; ------------------------------------------------------------------------------
; THE PWA VAULT & MEDIA PWA TARGETS
; ------------------------------------------------------------------------------
global PWAVault := Map()

for title in PWATitles {
    GroupAdd("MediaPWAs", title)
}

