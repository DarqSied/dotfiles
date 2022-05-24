  -- Base
import XMonad
import System.Directory
import System.IO (hPutStrLn)
import System.Exit (exitSuccess)
import qualified XMonad.StackSet as W

    -- Actions
import XMonad.Actions.CopyWindow (kill1)
import XMonad.Actions.CycleWS (Direction1D(..), moveTo, shiftTo, WSType(..), nextScreen, prevScreen)
import XMonad.Actions.MouseResize
import XMonad.Actions.Promote
import XMonad.Actions.RotSlaves (rotSlavesDown, rotAllDown)
import XMonad.Actions.WindowGo (runOrRaise)
import XMonad.Actions.WithAll (sinkAll, killAll)

    -- Data
import Data.Char (isSpace, toUpper)
import Data.Maybe (fromJust)
import Data.Monoid
import Data.Maybe (isJust)
import Data.Tree
import qualified Data.Map as M

    -- Hooks
import XMonad.Hooks.DynamicLog (dynamicLogWithPP, wrap, shorten, PP(..))
import XMonad.Hooks.EwmhDesktops  -- for some fullscreen events, also for xcomposite in obs.
-- import XMonad.Hooks.ManageDocks (avoidStruts, docksEventHook, manageDocks, ToggleStruts(..))
import XMonad.Hooks.ManageHelpers (isFullscreen, doFullFloat, doCenterFloat)
import XMonad.Hooks.ServerMode
import XMonad.Hooks.SetWMName
import XMonad.Hooks.WorkspaceHistory

    -- Layouts
import XMonad.Layout.SimplestFloat
import XMonad.Layout.ResizableTile
import XMonad.Layout.ThreeColumns

    -- Layouts modifiers
import XMonad.Layout.LayoutModifier
import XMonad.Layout.LimitWindows (limitWindows, increaseLimit, decreaseLimit)
import XMonad.Layout.MultiToggle (mkToggle, single, EOT(EOT), (??))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL, MIRROR, NOBORDERS))
import XMonad.Layout.NoBorders
import XMonad.Layout.Renamed
import XMonad.Layout.ShowWName
import XMonad.Layout.Simplest
import XMonad.Layout.Spacing
import XMonad.Layout.SubLayouts
import XMonad.Layout.WindowArranger (windowArrange, WindowArrangerMsg(..))
import XMonad.Layout.WindowNavigation
import qualified XMonad.Layout.ToggleLayouts as T (toggleLayouts, ToggleLayout(Toggle))
import qualified XMonad.Layout.MultiToggle as MT (Toggle(..))

   -- Utilities
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run (runProcessWithInput, safeSpawn, spawnPipe)
import XMonad.Util.SpawnOnce

myFont :: String
myFont = "xft:Hack Nerd Font Mono:regular:size=11:antialias=true:hinting=true"

myModMask :: KeyMask
myModMask = mod4Mask        -- Sets modkey to super/windows key

myTerminal :: String
myTerminal = "alacritty"    -- Sets default terminal

myEditor :: String
myEditor = myTerminal ++ " -e nvim "    -- Sets vim as editor

myBorderWidth :: Dimension
myBorderWidth = 2           -- Sets border width for windows

myNormColor :: String       -- Border color of normal windows
myNormColor   = "#282a36"   -- This variable is imported from Colors.THEME

myFocusColor :: String      -- Border color of focused windows
myFocusColor  = "#bd93f9"     -- This variable is imported from Colors.THEME

windowCount :: X (Maybe String)
windowCount = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset

myStartupHook :: X ()
myStartupHook = setWMName "LG3D"


myScratchPads :: [NamedScratchpad]
myScratchPads = [ NS "term" spawnTerm findTerm manageTerm
                , NS "spot" spawnSpot findSpot manageSpot
                , NS "mixer" spawnMix findMix manageMix
                ]
  where
    spawnTerm  = myTerminal ++ " -t scratchpad"
    findTerm   = title =? "scratchpad"
    manageTerm = customFloating $ W.RationalRect l t w h
               where
                 h = 0.9
                 w = 0.9
                 t = 0.95 -h
                 l = 0.95 -w
    spawnSpot  = myTerminal ++ " -t spot -e ncspot"
    findSpot   = title =? "spot"
    manageSpot = customFloating $ W.RationalRect l t w h
               where
                 h = 0.9
                 w = 0.9
                 t = 0.95 -h
                 l = 0.95 -w
    spawnMix  = myTerminal ++ " -t mixer -e pulsemixer"
    findMix   = title =? "mixer"
    manageMix = customFloating $ W.RationalRect l t w h
               where
                 h = 0.9
                 w = 0.9
                 t = 0.95 -h
                 l = 0.95 -w

--Makes setting the spacingRaw simpler to write. The spacingRaw module adds a configurable amount of space around windows.
mySpacing :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing i = spacingRaw True (Border i i i i) True (Border i i i i) True

-- Defining a bunch of layouts, many that I don't use.
-- limitWindows n sets maximum number of windows displayed for layout.
-- mySpacing n sets the gap size around the windows.
tall     = renamed [Replace "tall"]
           $ smartBorders
           $ windowNavigation
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 12
           $ mySpacing 5
           $ ResizableTall 1 (3/100) (1/2) []
monocle  = renamed [Replace "monocle"]
           $ smartBorders
           $ windowNavigation
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 20 Full
floats   = renamed [Replace "floats"]
           $ smartBorders
           $ limitWindows 20 simplestFloat
threeCol = renamed [Replace "threeCol"]
           $ smartBorders
           $ windowNavigation
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 6
           $ ThreeCol 1 (3/100) (1/2)

-- Theme for showWName which prints current workspace when you change workspaces.
myShowWNameTheme :: SWNConfig
myShowWNameTheme = def
    { swn_font              = "xft:Hack Font:bold:size=60"
    , swn_fade              = 1.0
    , swn_bgcolor           = "#282a36"
    , swn_color             = "#f8f8f2"
    }

-- The layout hook
myLayoutHook = smartBorders $ mouseResize $ windowArrange $ T.toggleLayouts floats
               $ mkToggle (NBFULL ?? NOBORDERS ?? EOT) myDefaultLayout
             where
               myDefaultLayout =     withBorder myBorderWidth tall
                                 ||| noBorders monocle
                                 ||| floats
                                 ||| threeCol

-- myWorkspaces = [" 1 ", " 2 ", " 3 ", " 4 ", " 5 ", " 6 ", " 7 ", " 8 ", " 9 "]
myWorkspaces = map show [1..6] ++ ["chat", "vid", "vbox" ]
myWorkspaceIndices = M.fromList $ zipWith (,) myWorkspaces [1..] -- (,) == \x y -> (x,y)

-- clickable ws = "<action=xdotool key super+"++show i++">"++ws++"</action>"
--     where i = fromJust $ M.lookup ws myWorkspaceIndices

myManageHook :: XMonad.Query (Data.Monoid.Endo WindowSet)
myManageHook = composeAll
     -- 'doFloat' forces a window to float.  Useful for dialog boxes and such.
     -- using 'doShift ( myWorkspaces !! 7)' sends program to workspace 8!
     -- I'm doing it this way because otherwise I would have to write out the full
     -- name of my workspaces and the names would be very long if using clickable workspaces.
     [ className =? "confirm"         --> doFloat
     , className =? "file_progress"   --> doFloat
     , className =? "dialog"          --> doFloat
     , className =? "download"        --> doFloat
     , className =? "error"           --> doFloat
     , className =? "notification"    --> doFloat
     , className =? "pinentry-gtk-2"  --> doFloat
     , className =? "splash"          --> doFloat
     , className =? "toolbar"         --> doFloat
     , className =? "Yad"             --> doCenterFloat
     , className =? "mpv"             --> doCenterFloat
     , className =? "mpv"             --> doShift ( myWorkspaces !! 7 )
     , (className =? "librewolf" <&&> resource =? "Dialog") --> doFloat  -- Float Librewolf Dialog
     , isFullscreen -->  doFullFloat
     ] <+> namedScratchpadManageHook myScratchPads

-- START_KEYS
myKeys :: [(String, X ())]
myKeys =
    -- KB_GROUP Xmonad
        [ ("M-C-r", spawn "xmonad --recompile; xmonad --restart")                                           -- Restart xmonad
        , ("M-C-q", io exitSuccess)                                                                         -- Quit xmonad

    -- KB_GROUP Get Help
        , ("M-S-/", spawn "~/.xmonad/xmonad_keys.sh")                                                       -- Get list of keybindings

    -- KB_GROUP Rofi Prompts
        , ("M-r", spawn "rofi -show combi -combi-modi 'window,drun' -modi combi -show-icons")               -- Run desktop apps
        , ("M-S-r", spawn "rofi -show run -modi 'run'")                                                     -- Run prompt
        , ("M-v", spawn "rofi -modi 'clipboard:greenclip print' -show clipboard -run-command '{cmd}'")      -- Clipboard manager
        , ("M-S-v", spawn "rofi -show emoji -modi 'emoji'")                                                 -- Emoji selector
        , ("M-n", spawn "networkmanager_dmenu")                                                             -- NM_dmenu
        , ("M-b", spawn "bookman")                                                                          -- Bookmark list
        , ("M-S-d", spawn "torr")                                                                           -- Torrent search
        , ("M-C-x", spawn "rofi -show powermenu -modi powermenu:powermenu")                                 -- Powermenu

    -- KB_GROUP Useful programs to have a keybinding for launch
        , ("M-<Return>", spawn (myTerminal))                                                                -- Launch terminal
        , ("M-S-<Return>", spawn (myTerminal ++ " -e atmux"))                                               -- Launch tmux
        , ("M-w", spawn "qutebrowser")                                                                      -- Launch qutebrowser
        , ("M-M1-w", spawn "librewolf")                                                                     -- Launch librewolf
        , ("M-S-w", spawn "librewolf --private-window")                                                     -- Launch librewolf-private
        , ("M-e", spawn (myTerminal ++ " -e lfrun"))                                                        -- Launch lf
        , ("M-S-e", spawn "thunar")                                                                         -- Launch thunar
        , ("M-a", spawn (myTerminal ++ " -e btop"))                                                         -- Launch system monitor
        , ("M-d", spawn (myTerminal ++ " -e tremc"))                                                        -- Launch transmission
        , ("M-c", spawn "clock")                                                                            -- Time & date
        , ("M-S-c", spawn "cal-popup --popup")                                                              -- Launch mini calender
        , ("M-o", spawn "overview")                                                                         -- System overview
        , ("M-<F10>", spawn "feh --no-fehbg --bg-fill -z ~/.config/backgrounds")                            -- Shuffle desktop background

    -- KB_GROUP Kill windows
        , ("M-q", kill1)                                                                                    -- Kill the currently focused client
        , ("M-M1-q", killAll)                                                                               -- Kill all windows on current workspace
        , ("M-S-q", spawn "xkill")                                                                          -- Launch xkill

    -- KB_GROUP Workspaces
        , ("M-.", nextScreen)                                                                               -- Switch focus to next monitor
        , ("M-,", prevScreen)                                                                               -- Switch focus to prev monitor
        , ("M-S-<KP_Add>", shiftTo Next nonNSP >> moveTo Next nonNSP)                                       -- Shifts focused window to next ws
        , ("M-S-<KP_Subtract>", shiftTo Prev nonNSP >> moveTo Prev nonNSP)                                  -- Shifts focused window to prev ws

    -- KB_GROUP Floating windows
        , ("M-f", sendMessage (T.Toggle "floats"))                                                          -- Toggles my 'floats' layout
        , ("M-C-t", withFocused $ windows . W.sink)                                                         -- Push floating window back to tile
        , ("M-t", sinkAll)                                                                                  -- Push ALL floating windows to tile

    -- KB_GROUP Increase/decrease spacing (gaps)
        , ("C-M1-j", decWindowSpacing 5)                                                                    -- Decrease window spacing
        , ("C-M1-k", incWindowSpacing 5)                                                                    -- Increase window spacing
        , ("C-M1-h", decScreenSpacing 5)                                                                    -- Decrease screen spacing
        , ("C-M1-l", incScreenSpacing 5)                                                                    -- Increase screen spacing

    -- KB_GROUP Windows navigation
        , ("M-S-m", windows W.focusMaster)                                                                  -- Move focus to the master window
        , ("M-j", windows W.focusDown)                                                                      -- Move focus to the next window
        , ("M-k", windows W.focusUp)                                                                        -- Move focus to the prev window
        , ("M-C-m", windows W.swapMaster)                                                                   -- Swap the focused window and the master window
        , ("M-C-j", windows W.swapDown)                                                                     -- Swap focused window with next window
        , ("M-C-k", windows W.swapUp)                                                                       -- Swap focused window with prev window
        , ("M-M1-m>", promote)                                                                              -- Moves focused window to master, others maintain order
        , ("M-M1-<Tab>", rotSlavesDown)                                                                     -- Rotate all windows except master and keep focus in place
        , ("M-C-<Tab>", rotAllDown)                                                                         -- Rotate all the windows in the current stack

    -- KB_GROUP Layouts
        , ("M-<Tab>", sendMessage NextLayout)                                                               -- Switch to next layout
        , ("M-m", sendMessage (MT.Toggle NBFULL))                                                           -- Toggles noborder/full

    -- KB_GROUP Increase/decrease windows in the master pane or the stack
        , ("M-S-<Up>", sendMessage (IncMasterN 1))                                                          -- Increase # of clients master pane
        , ("M-S-<Down>", sendMessage (IncMasterN (-1)))                                                     -- Decrease # of clients master pane
        , ("M-C-<Up>", increaseLimit)                                                                       -- Increase # of windows
        , ("M-C-<Down>", decreaseLimit)                                                                     -- Decrease # of windows

    -- KB_GROUP Window resizing
        , ("M-h", sendMessage Shrink)                                                                       -- Shrink horiz window width
        , ("M-l", sendMessage Expand)                                                                       -- Expand horiz window width
        , ("M-M1-j", sendMessage MirrorShrink)                                                              -- Shrink vert window width
        , ("M-M1-k", sendMessage MirrorExpand)                                                              -- Expand vert window width

    -- KB_GROUP Scratchpads
    -- Toggle show/hide these programs.  They run on a hidden workspace.
    -- When you toggle them to show, it brings them to your current workspace.
    -- Toggle them to hide and it sends them back to hidden workspace (NSP).
        , ("M-x", namedScratchpadAction myScratchPads "term")
        , ("M-s", namedScratchpadAction myScratchPads "spot")
        , ("M-p", namedScratchpadAction myScratchPads "mixer")

    -- KB_GROUP Multimedia Keys
        , ("<XF86AudioPlay>", spawn "playerctl play-pause")
        , ("<XF86AudioPrev>", spawn "playerctl previous")
        , ("<XF86AudioNext>", spawn "playerctl next")
        , ("<XF86AudioStop>", spawn "playerctl stop")
        , ("<XF86AudioMute>", spawn "volume mute")
        , ("<XF86AudioLowerVolume>", spawn "volume down")
        , ("<XF86AudioRaiseVolume>", spawn "volume up")

    -- KB_GROUP Brightness Control
        , ("<XF86MonBrightnessUp>", spawn "brightnessctl set +10%")
        , ("<XF86MonBrightnessDown>", spawn "brightnessctl set 10%-")

    -- KB_GROUP Screenshot
        , ("<Print>", spawn "flameshot full -p ~/Himanshu/Data/Screenshots/")
        , ("M1-<Print>", spawn "flameshot screen -p ~/Himanshu/Data/Screenshots/")
        , ("C-<Print>", spawn "flameshot gui -p ~/Himanshu/Data/Screenshots/")

    -- KB_GROUP Notification Control
        , ("M-`", spawn "dunstctl close")
        , ("M-M1-`", spawn "dunstctl close-all")
        , ("M-S-`", spawn "dunstctl history-pop")
        , ("M-C-`", spawn "dunstctl set-paused toggle")
        ]
    -- The following lines are needed for named scratchpads.
          where nonNSP          = WSIs (return (\ws -> W.tag ws /= "NSP"))
                nonEmptyNonNSP  = WSIs (return (\ws -> isJust (W.stack ws) && W.tag ws /= "NSP"))
-- END_KEYS

main :: IO ()
main = do
    xmonad $ ewmh def
        { manageHook         = myManageHook
        , handleEventHook    = fullscreenEventHook
                               -- Uncomment this line to enable fullscreen support on things like YouTube/Netflix.
                               -- This works perfect on SINGLE monitor systems. On multi-monitor systems,
                               -- it adds a border around the window if screen does not have focus. So, my solution
                               -- is to use a keybinding to toggle fullscreen noborders instead.  (M-<Space>)
        , modMask            = myModMask
        , terminal           = myTerminal
        , startupHook        = myStartupHook
        , layoutHook         = showWName' myShowWNameTheme $ myLayoutHook
        , workspaces         = myWorkspaces
        , borderWidth        = myBorderWidth
        , normalBorderColor  = myNormColor
        , focusedBorderColor = myFocusColor
        , logHook = dynamicLogWithPP . namedScratchpadFilterOutWorkspacePP $ def
        } `additionalKeysP` myKeys

