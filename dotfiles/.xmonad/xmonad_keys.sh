#!/usr/bin/env bash
set -euo pipefail


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
    -e 's/) / /g' \
    -e 's/" ,/ ,/g' \
    -e 's/, /: /' | \
    yad --text-info --geometry=1400x900 --no-buttons

