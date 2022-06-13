#!/usr/bin/env bash
set -euo pipefail

# Launches an YAD text box with all the keybindings of xmonad
# in the center of the screen

YAD_WIDTH=1480
YAD_HEIGHT=950
CUR_X=$(xdotool getdisplaygeometry | awk '{print $1}')
CUR_Y=$(xdotool getdisplaygeometry | awk '{print $NF}')

pos_x=$((($CUR_X - $YAD_WIDTH) / 2))
pos_y=$((($CUR_Y - $YAD_HEIGHT) / 2))

sed -n '/START_KEYS/,/END_KEYS/p' ~/.xmonad/xmonad.hs | \
    grep -e ', ("' \
    -e '\[ (' \
    -e 'KB_GROUP' | \
    grep -v '\-\- , ("' | \
    sed -e 's/^[ \t]*//' \
    -e 's/, (/(/' \
    -e 's/\[ (/(/' \
    -e 's/-- KB_GROUP /\n/' \
    -e 's/("/   /' \
    -e 's/"  /  /g' \
    -e 's/)//' \
    -e 's/" ,/ ,/g' \
    -e 's/ , / : /' | \
    yad --text-info --no-buttons \
    --width="$YAD_WIDTH" --height="$YAD_HEIGHT" --posx="$pos_x" --posy="$pos_y" \
    --title="Keybindings" >/dev/null &


