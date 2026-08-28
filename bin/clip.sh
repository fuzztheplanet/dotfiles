#!/bin/sh
# clip — single clipboard backend for every tool in these dotfiles.
#
#   ... | clip        copy stdin to CLIPBOARD
#   ... | clip -p     copy stdin to PRIMARY
#   clip -o           print CLIPBOARD
#   clip -o -p        print PRIMARY
#
# Backends, in order: wl-clipboard (Wayland), xclip (X11), OSC 52 (no display,
# e.g. SSH: reaches the local terminal only if it supports OSC 52; tmux
# always stores it as a paste buffer).
set -eu

sel=clipboard
mode=copy
while getopts "op" f; do
    case $f in
        o) mode=paste ;;
        p) sel=primary ;;
        *) echo "usage: clip [-o] [-p]" >&2; exit 2 ;;
    esac
done

if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
    flag=""
    [ "$sel" = primary ] && flag="--primary"
    if [ "$mode" = copy ]; then exec wl-copy $flag
    else                        exec wl-paste --no-newline $flag
    fi
elif [ -n "${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
    if [ "$mode" = copy ]; then exec xclip -i -selection "$sel"
    else                        exec xclip -o -selection "$sel"
    fi
elif [ "$mode" = copy ]; then
    b64=$(base64 | tr -d '\n')
    if [ -n "${TMUX:-}" ]; then seq=$(printf '\033Ptmux;\033\033]52;c;%s\a\033\\' "$b64")
    else                        seq=$(printf '\033]52;c;%s\a' "$b64")
    fi
    # Write to the controlling terminal; fall back to stdout if there is none.
    { printf '%s' "$seq" > /dev/tty; } 2>/dev/null || printf '%s' "$seq"
else
    echo "clip: no display and OSC 52 cannot read the clipboard" >&2
    exit 1
fi
