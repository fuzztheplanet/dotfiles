#!/bin/sh

SESS="monitor"

WEATHER="while true; do clear ; date ; curl wttr.in/?nFQ ; sleep $(( 2 * 60 * 60 )) ; done"

ACPI="watch -n 120 acpi -V"

if tmux has-session -t "${SESS}" 2>/dev/null ; then

    tmux attach -t "${SESS}"

else
    cd "${HOME}" || exit 1

    # Window 1) "processes & disk space"
    tmux new -s "${SESS}" -d -n "monitor" htop -t
    tmux split-window -v -l '30%' watch -n 60 -t df -h
    tmux split-window -h -l '35%'
    tmux clock-mode -t 3

    # Window 2) "network"
    tmux new-window -n "net" watch -n 30 -t ip a
    tmux split-window -v -l '20%' watch -n 30 -t ip r

    # Window 3) "weather"
    tmux new-window -n "weather" "${WEATHER}"

    # Window 4) "acpi"
    tmux new-window -n "acpi" "${ACPI}"

    # Back to window 1) and first pane
    tmux select-window -t ${SESS}:1
    tmux select-pane -t 1
fi
