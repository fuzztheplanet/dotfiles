#!/usr/bin/env bash


# USAGE: kill_tmux.sh
# This script uses dmenu


all_sessions=$(tmux ls | cut -d':' -f1 | dmenu -p "kill tmux> ")

[[ "$?" -ne 0 ]] && { echo "User aborted!"; exit 0; }

echo "Got selected session: ${selected_session}"

tmux kill-session -t "${selected_session}"
