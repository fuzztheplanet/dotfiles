#!/usr/bin/env bash

# USAGE: attach-tmux.sh
# This script uses dmenu

set -u

selected_session=$(tmux ls -F '#S' | dmenu -p "attach tmux> ") || { echo "User aborted!"; exit 0; }
[[ -n "${selected_session}" ]] || { echo "No session selected!"; exit 0; }

echo "Got selected session: ${selected_session}"

i3-sensible-terminal -e tmux attach-session -t "${selected_session}"
