#!/usr/bin/env bash
set -euo pipefail

# Launches a YAD text box with all the keybindings of xmonad in the center of the screen

YAD_WIDTH=1480
YAD_HEIGHT=950
read CUR_X CUR_Y <<< $(xdotool getdisplaygeometry | awk '{print $1, $NF}')

pos_x=$((($CUR_X - $YAD_WIDTH) / 2))
pos_y=$((($CUR_Y - $YAD_HEIGHT) / 2))

sed -n '/START_KEYS/,/END_KEYS/p' ~/.xmonad/xmonad.hs | \
    sed -e '/^\s*--/d' \
        -e 's/\s*\(KB_GROUP\|, ("\|, \[\) */\n/g' \
        -e 's/\("\|\]\),\?\s*/ /g' \
        -e 's/\s*)/\n/g' \
    | yad --text-info --no-buttons \
          --width="$YAD_WIDTH" --height="$YAD_HEIGHT" --posx="$pos_x" --posy="$pos_y" \
          --title="Keybindings" >/dev/null &