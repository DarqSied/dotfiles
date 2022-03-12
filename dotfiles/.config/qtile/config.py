# -*- coding: utf-8 -*-
import os
import re
import socket
import subprocess
from libqtile import qtile
from typing import List  # noqa: F401
from libqtile import layout, bar, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen, Rule
from libqtile.lazy import lazy
from libqtile.command import lazy
from libqtile.widget import Spacer


mod = "mod4"
terminal = "alacritty"

@lazy.function
def window_to_prev_group(qtile):
    if qtile.currentWindow is not None:
        i = qtile.groups.index(qtile.currentGroup)
        qtile.currentWindow.togroup(qtile.groups[i - 1].name)

@lazy.function
def window_to_next_group(qtile):
    if qtile.currentWindow is not None:
        i = qtile.groups.index(qtile.currentGroup)
        qtile.currentWindow.togroup(qtile.groups[i + 1].name)

@lazy.function
def window_to_previous_screen(qtile):
    i = qtile.screens.index(qtile.current_screen)
    if i != 0:
        group = qtile.screens[i - 1].group.name
        qtile.current_window.togroup(group)

@lazy.function
def window_to_next_screen(qtile):
    i = qtile.screens.index(qtile.current_screen)
    if i + 1 != len(qtile.screens):
        group = qtile.screens[i + 1].group.name
        qtile.current_window.togroup(group)

@lazy.function
def switch_screens(qtile):
    i = qtile.screens.index(qtile.current_screen)
    group = qtile.screens[i - 1].group
    qtile.current_screen.set_group(group)

keys = [

    # Launch terminal, kill window, restart and exit Qtile
    Key([mod], "Return", lazy.spawn(terminal)),
    Key([mod], "q", lazy.window.kill()),
    Key([mod, "shift"], "q", lazy.spawn('xkill')),
    Key([mod, "mod1"], "r", lazy.restart()),

    # Rofi
    Key([mod], "r", lazy.spawn('rofi -show combi -combi-modi "window,drun" -modi combi -show-icons')),
    Key([mod, "shift"], "r", lazy.spawn('rofi -modi "run" -show run')),
    Key([mod], "v", lazy.spawn('rofi -modi "clipboard:greenclip print" -show clipboard -run-command "{cmd}"')),
    Key([mod, "shift"], "v", lazy.spawn('rofi -modi "emoji" -show emoji')),
    Key([mod, "mod1"], "x", lazy.spawn('rofi -show powermenu -modi powermenu:~/.local/bin/powermenu')),

    # Custom key bindings
    Key([mod], "w", lazy.spawn("librewolf")),
    Key([mod, "shift"], "w", lazy.spawn("librewolf --private-window")),
    Key([mod], "e", lazy.spawn(terminal + ' -e /home/darksied/.local/bin/lfrun')),
    Key([mod, "shift"], "e", lazy.spawn("thunar")),
    Key([mod], "s", lazy.spawn(terminal + ' -e ncspot')),
    Key([mod], "a", lazy.spawn(terminal + ' -e htop')),
    Key([mod], "d", lazy.spawn(terminal + ' -e pulsemixer')),

    # Screenshot
    Key([], "Print", lazy.spawn("flameshot full -p /home/darksied/Himanshu/Data/Backup/Screenshots")),
    Key(["mod1"], "Print", lazy.spawn("flameshot screen -p /home/darksied/Himanshu/Data/Backup/Screenshots")),
    Key(["control"], "Print", lazy.spawn("flameshot gui -p /home/darksied/Himanshu/Data/Backup/Screenshots")),

    # Volume+Media keys
    Key([], "XF86AudioMute", lazy.spawn("amixer -D pulse set Master 1+ toggle")),
    Key([], "XF86AudioLowerVolume", lazy.spawn("amixer set Master 5%-")),
    Key([], "XF86AudioRaiseVolume", lazy.spawn("amixer set Master 5%+")),
    Key([], "XF86AudioPlay", lazy.spawn("playerctl play-pause")),
    Key([], "XF86AudioStop", lazy.spawn("playerctl stop")),
    Key([], "XF86AudioNext", lazy.spawn("playerctl next")),
    Key([], "XF86AudioPrev", lazy.spawn("playerctl previous")),

    # Brightness Keys
    Key([], "XF86MonBrightnessUp", lazy.spawn("xbacklight -inc 10")),
    Key([], "XF86MonBrightnessDown", lazy.spawn("xbacklight -dec 10")),

    # Notification controls
    Key([mod], "grave", lazy.spawn("dunstctl close")),
    Key([mod, "mod1"], "grave", lazy.spawn("dunstctl close-all")),
    Key([mod, "shift"], "grave", lazy.spawn("dunstctl history-pop")),
    Key([mod, "control"], "grave", lazy.spawn("dunstctl set-paused toggle")),

    # Toggle layouts
    Key([mod], "space", lazy.next_layout()),
    Key([mod], "n", lazy.layout.normalize()),
    Key([mod], "b", lazy.window.toggle_floating()),
    Key([mod], "m", lazy.window.toggle_fullscreen()),

   # Change window focus
    Key([mod], "k", lazy.layout.up()),
    Key([mod], "j", lazy.layout.down()),

   # Switch focus to a physical monitor (dual/triple set up)
    Key([mod], "period", lazy.next_screen()),
    Key([mod], "comma", lazy.prev_screen()),
    Key([mod], "u", lazy.to_screen(0)),
    Key([mod], "i", lazy.to_screen(1)),
    Key([mod], "o", lazy.to_screen(2)),

   # Move windows to different physical screens
    Key([mod, "shift"], "period", lazy.function(window_to_previous_screen)),
    Key([mod, "shift"], "comma", lazy.function(window_to_next_screen)),
    Key([mod], "y", lazy.function(switch_screens)),


   # Resize layout
    Key([mod], "l",
        lazy.layout.decrease_nmaster(),
        lazy.layout.grow(),
        ),
    Key([mod], "h",
        lazy.layout.increase_nmaster(),
        lazy.layout.shrink(),
        ),

   # Flip left and right pains and move windows
    Key([mod], "p", lazy.layout.flip()),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up()),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down()),
    Key([mod, "shift"], "h", lazy.layout.swap_left()),
    Key([mod, "shift"], "l", lazy.layout.swap_right()),

		]

groups = []

   # Allocate layouts and labels
group_names = ["1", "2", "3", "4", "5", "6", "7", "8", "9",]
group_labels = ["", "", "漣", "ﴬ", "", "", "", "辶", "",]
group_layouts = ["monadtall", "monadtall", "monadtall", "monadtall", "monadtall", "monadtall", "monadtall", "monadtall", "monadtall",]

for i in range(len(group_names)):
    groups.append(
        Group(
            name=group_names[i],
            layout=group_layouts[i].lower(),
            label=group_labels[i],
        ))

for i in groups:
    keys.extend([

   # Workspace navigation
    Key([mod], i.name, lazy.group[i.name].toscreen()),
    Key([mod], "Tab", lazy.screen.next_group()),
    Key([mod, "shift"], i.name, lazy.window.togroup(i.name)),
    Key([mod, "control"], i.name, lazy.window.togroup(i.name) , lazy.group[i.name].toscreen()),
    ])


def init_layout_theme():
    return {"margin":5,
            "border_width":2,
            "border_focus": "#bd93f9",
            "border_normal": "#f4c2c2"
            }

layout_theme = init_layout_theme()


layouts = [
    layout.MonadTall(margin=5, border_width=2, border_focus="#bd93f9", border_normal="#44475a"),
    # layout.MonadWide(margin=5, border_width=2, border_focus="#bd93f9", border_normal="#44475a")
    # layout.Columns(**layout_theme),
    # layout.Stack(stacks=2, **layout_theme),
    # layout.Floating(**layout_theme),
    layout.Max(**layout_theme),
]

   # Bar colours
def init_colors():
    return [["#282a36", "#282a36"], # color 0
            ["#282a36", "#282a36"], # color 1
            ["#44475a", "#44475a"], # color 2
            ["#ffb86c", "#ffb86c"], # color 3
            ["#6272a4", "#6272a4"], # color 4
            ["#f8f8f2", "#f8f8f2"], # color 5
            ["#ff5555", "#ff5555"], # color 6
            ["#50fa7b", "#50fa7b"], # color 7
            ["#bd93f9", "#bd93f9"]] # color 8


colors = init_colors()


   # Widgets
def init_widgets_defaults():
    return dict(font="Hack Nerd Font",
                fontsize = 15,
                padding = 2)

widget_defaults = init_widgets_defaults()

def init_widgets_list():
    prompt = "{0}@{1}: ".format(os.environ["USER"], socket.gethostname())
    widgets_list = [
               widget.GroupBox(font="Hack Nerd Font",
                        fontsize = 22,
                        margin_y = 3,
                        margin_x = 0,
                        padding_y = 6,
                        padding_x = 5,
                        borderwidth = 0,
                        disable_drag = True,
                        active = colors[2],
                        inactive = colors[5],
                        rounded = False,
                        highlight_method = "text",
                        this_current_screen_border = colors[8],
                        foreground = colors[2]
                        ),
               widget.Sep(
                        linewidth = 1,
                        padding = 10,
                        foreground = colors[2]
                        ),
               widget.CurrentLayout(
                        font = "Hack Nerd Font",
                        foreground = colors[5]
                        ),
               widget.Sep(
                        linewidth = 1,
                        padding = 10,
                        foreground = colors[2]
                        ),
               widget.WindowName(
                        font="Hack Nerd Font",
                        fontsize = 15,
                        max_chars = 50,
                        foreground = colors[5]
                        ),
               widget.Net(
                        font = "FontAwesome",
                        fontsize = 14,
                        interface = "wlp3s0",   # to check ` iw dev `
                        format = '{up}  {down}',
                        foreground = colors[5],
                        padding = 0
                        ),
               widget.Sep(
                        linewidth = 1,
                        padding = 10,
                        foreground = colors[2]
                        ),
               widget.TextBox(
                        font = "FontAwesome",
                        text = "  ",
                        foreground = colors[6],
                        padding = 0,
                        fontsize = 15
                        ),
               widget.CPU(
                        font = "Hack Nerd Font",
                        fontsize = 14,
                        format = ' CPU {load_percent}%',
                        foreground = colors[5],
                        padding = 0
                        ),
               widget.Sep(
                        linewidth = 1,
                        padding = 10,
                        foreground = colors[2]
                        ),
               widget.TextBox(
                        font = "FontAwesome",
                        text = "  ",
                        foreground = colors[4],
                        padding = 0,
                        fontsize = 15
                        ),
               widget.Memory(
                        font = "Hack Nerd Font",
                        format = '{MemUsed: .0f}{mm}/{MemTotal: .0f}{mm}',
                        update_interval = 1,
                        fontsize = 14,
                        foreground = colors[5]
                        ),
               widget.Sep(
                        linewidth = 1,
                        padding = 10,
                        foreground = colors[2]
                        ),
               widget.Battery(
                        font="FontAwesome",
                        update_interval = 10,
                        charge_char = '  ',
                        discharge_char = '  ',
                        empty_char = '  ',
                        full_char = '  ',
                        format = '{char} {percent:2.0%}',
                        low_percentage = 0.3,
                        fontsize = 15,
                        foreground = colors[5],
                        low_foreground = colors[3]
	                    ),
               widget.Sep(
                        linewidth = 1,
                        padding = 10,
                        foreground = colors[2]
                        ),
               widget.TextBox(
                        font="FontAwesome",
                        text = "  ",
                        foreground = colors[7],
                        padding = 0,
                        fontsize = 15
                        ),
               widget.Volume(
                        font="Hack Nerd Font",
                        fontsize = 14,
                        step = 5,
                        channel = 'Master',
                        foreground = colors[5],
                        padding = 3
                        ),
               widget.Sep(
                        linewidth = 1,
                        padding = 10,
                        foreground = colors[2]
                        ),
               widget.TextBox(
                        font = "FontAwesome",
                        text = "  ",
                        foreground = colors[3],
                        padding = 2,
                        fontsize = 15
                        ),
               widget.Clock(
                        font="Hack Nerd Font",
                        foreground = colors[5],
                        fontsize = 14,
                        mouse_callbacks = {'Button1': lambda: qtile.cmd_spawn('/home/darksied/.local/bin/cal-popup --popup')},
                        format = '%d/%m/%y  %H:%M'
                        ),
               widget.Sep(
                        linewidth = 1,
                        padding = 10,
                        foreground = colors[2]
                        ),
               widget.Systray(
                        icon_size = 20,
                        padding = 4
                        ),
             ]
    return widgets_list

widgets_list = init_widgets_list()


def init_widgets_screen1():
    widgets_screen1 = init_widgets_list()
    return widgets_screen1

def init_widgets_screen2():
    widgets_screen2 = init_widgets_list()
    return widgets_screen2

widgets_screen1 = init_widgets_screen1()
widgets_screen2 = init_widgets_screen2()


def init_screens():
    return [Screen(top=bar.Bar(widgets=init_widgets_screen1(), size=25, background="#00000000", opacity=1)),
            Screen(top=bar.Bar(widgets=init_widgets_screen2(), size=25, background="#00000000", opacity=1)),
            Screen(top=bar.Bar(widgets=init_widgets_screen1(), size=25, background="#00000000", opacity=1))]

screens = init_screens()


   # Mouse config
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front())
]

dgroups_key_binder = None
dgroups_app_rules = []

    # Assign applications to specific groupnames
# @hook.subscribe.client_new
# def assign_app_group(client):
#     d = {}
#     #########################################################
#     d["1"] = ["Navigator", "Librewolf", "Vivaldi-stable", "Vivaldi-snapshot", "Chromium", "Google-chrome", "Brave", "Brave-browser",
#               "navigator", "librewolf", "vivaldi-stable", "vivaldi-snapshot", "chromium", "google-chrome", "brave", "brave-browser", ]
#     d["5"] = ["VirtualBox Manager", "VirtualBox Machine", "Vmplayer",
#               "virtualbox manager", "virtualbox machine", "vmplayer", ]
#     d["6"] = ["Evolution", "Geary", "Mail", "Thunderbird",
#               "evolution", "geary", "mail", "thunderbird" ]
#     d["7"] = ["Spotify", "Pragha", "Clementine", "Deadbeef", "Audacious",
#               "spotify", "pragha", "clementine", "deadbeef", "audacious" ]
#     d["8"] = ["Vlc","vlc", "Mpv", "mpv" ]
#     ##########################################################
#     wm_class = client.window.get_wm_class()[0]
#
#     for i in range(len(d)):
#         if wm_class in list(d.values())[i]:
#             group = list(d.keys())[i]
#             client.togroup(group)
#             client.group.cmd_toscreen()
#
# main = None

@hook.subscribe.startup
def start_always():
    # Set the cursor to something sane in X
    subprocess.Popen(['xsetroot', '-cursor_name', 'left_ptr'])

@hook.subscribe.client_new
def set_floating(window):
    if (window.window.get_wm_transient_for()
            or window.window.get_wm_type() in floating_types):
        window.floating = True

floating_types = ["notification", "toolbar", "splash", "dialog"]


follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(float_rules=[
    # Run the utility of `xprop` to see the wm class and name of an X client.
    *layout.Floating.default_float_rules,
    Match(wm_class='confirmreset'),  # gitk
    Match(wm_class='makebranch'),  # gitk
    Match(wm_class='maketag'),  # gitk
    Match(wm_class='ssh-askpass'),  # ssh-askpass
    Match(title='branchdialog'),  # gitk
    Match(title='pinentry'),  # GPG key password entry
    Match(wm_class='Arcolinux-welcome-app.py'),
    Match(wm_class='Arcolinux-tweak-tool.py'),
    Match(wm_class='Arcolinux-calamares-tool.py'),
    Match(wm_class='confirm'),
    Match(wm_class='dialog'),
    Match(wm_class='download'),
    Match(wm_class='error'),
    Match(wm_class='file_progress'),
    Match(wm_class='notification'),
    Match(wm_class='splash'),
    Match(wm_class='toolbar'),
    Match(wm_class='Arandr'),
    Match(wm_class='feh'),
    Match(wm_class='Galculator'),
    Match(wm_class='arcolinux-logout'),

],  fullscreen_border_width = 0, border_width = 0)
auto_fullscreen = True

focus_on_window_activation = "smart" # or focus

auto_minimize = True

wmname = "LG3D"
