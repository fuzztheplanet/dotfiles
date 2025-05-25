#!/bin/sh

SESS="blog"

if tmux has-session -t "${SESS}" 2>/dev/null; then

    tmux attach -t "${SESS}"

else
    cd ~/org/blog || exit 1

    # Window 1) "files"
    tmux new -s "${SESS}" -d -n "files" ranger

    # Window 2) "run"
    tmux new-window -n "run"
    tmux split-window -v -l '30%' make run
    tmux select-pane -U

    tmux attach -t "${SESS}"

fi
