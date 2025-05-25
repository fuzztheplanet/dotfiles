#!/usr/bin/env bash


# USAGE: attach_tmux.sh
# This script uses dmenu


all_sessions=$(tmux ls | cut -d':' -f1 | dmenu -p "attach tmux> ")

[[ "$?" -ne 0 ]] && { echo "User aborted!"; exit 0; }

echo "Got selected session: ${selected_session}"

i3-sensible-terminal -e tmux attach-session -t "${selected_session}"
