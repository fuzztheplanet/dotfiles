#!/usr/bin/env bash

# USAGE: kill-tmux.sh
# This script uses dmenu

set -u

selected_session=$(tmux ls -F '#S' | dmenu -p "kill tmux> ") || { echo "User aborted!"; exit 0; }
[[ -n "${selected_session}" ]] || { echo "No session selected!"; exit 0; }

echo "Got selected session: ${selected_session}"

tmux kill-session -t "${selected_session}"
