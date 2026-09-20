#!/usr/bin/env bash
# ft.sh: fuzzy tmux sessions with fzf. One entry point shared by bash ('ft'),
# the tmux popup (prefix C-s) and i3 (Mod+Return).
#
# Enter:           attach / switch to the session, or create it from the query
# C-o:             open a new grouped "view" of the session (name#N)
# C-r:             kill selection
# M-n:             rename session
# M-i:             copy selection to clipboard
# M-a / M-d:       (de)select everything
# C-j / C-k, C-/:  navigate preview
#
# The keybindings call back into this script with the _subcommands below, so
# the fzf actions stay free of quoting tricks. Attaching happens after fzf has
# exited, on the script's own stdin: an fzf 'become' action would hand tmux a
# descriptor named /dev/tty, which the tmux server cannot open ("open terminal
# failed: can't use /dev/tty").
set -u

self=$(readlink -f "$0")
clip="$(dirname "$self")/clip.sh"

# Attach when outside tmux, switch-client when inside a popup or a nested shell.
goto() {
    if [ -n "${TMUX:-}" ]; then
        tmux switch-client -t "=$1"
    else
        exec tmux attach-session -t "=$1"
    fi
}

case "${1:-}" in
    _list)
        tmux list-sessions \
            -F '#{session_name}	#{session_windows} win	#{?session_attached,attached,detached}	#{t/f/%d %b %H#:%M:session_activity}' \
            2>/dev/null || :
        ;;
    _enter) # $2: selected session (may be empty), $3: query
        name=${2:-${3:-}}
        [ -z "$name" ] && exit 0
        tmux has-session -t "=$name" 2>/dev/null \
            || tmux new-session -d -s "$name" -c "$HOME" || exit 1
        goto "$name"
        ;;
    _view) # $2: base session
        [ -z "${2:-}" ] && exit 0
        base=${2%%#*}
        n=$(tmux list-sessions -F '#S' | grep -c "^${base}#")
        n=$((n + 1))
        tmux new-session -d -s "${base}#${n}" -t "=$base" || exit 1
        goto "${base}#${n}"
        ;;
    _kill) # $2..: sessions
        shift
        for s in "$@"; do tmux kill-session -t "=$s"; done
        ;;
    _rename) # $2: session
        read -rp "New name for '$2': " new
        [ -n "$new" ] && tmux rename-session -t "=$2" "$new"
        ;;
    _preview) # $2: session
        tmux list-windows -t "=$2" \
            -F '#{window_index}: #{window_name}#{?window_active, *,}'
        echo
        tmux capture-pane -ep -t "=$2:" | tail -n 30
        ;;
    "")
        # Output: line 1 the query, line 2 the key that ended fzf (empty for
        # Enter), line 3+ the selection. Exit code 1 means no match (create).
        out=$(fzf --multi --ansi \
            --reverse --border --height 60% \
            --delimiter '\t' --tabstop 4 \
            --prompt 'tmux> ' \
            --header 'Enter: attach or create | C-o: new view | C-r: kill | M-n: rename' \
            --print-query --expect=ctrl-o \
            --bind "start:reload($self _list)" \
            --bind "change:reload($self _list)" \
            --bind "ctrl-r:execute-silent($self _kill {+1})+reload($self _list)" \
            --bind "alt-n:execute($self _rename {1})+reload($self _list)" \
            --bind "alt-i:execute-silent(printf '%s\n' {+1} | $clip)" \
            --bind 'alt-a:select-all,alt-d:deselect-all' \
            --bind 'ctrl-j:preview-down,ctrl-k:preview-up,ctrl-/:toggle-preview' \
            --preview "$self _preview {1}" \
            --preview-window 'down,60%')
        rc=$?
        case "$rc" in 0|1) ;; *) exit 0 ;; esac   # 130: aborted, 2: fzf error
        query=$(printf '%s\n' "$out" | sed -n 1p)
        key=$(printf '%s\n' "$out" | sed -n 2p)
        sel=$(printf '%s\n' "$out" | sed -n 3p | cut -f1)
        if [ "$key" = ctrl-o ]; then
            exec "$self" _view "$sel"
        else
            exec "$self" _enter "$sel" "$query"
        fi
        ;;
    *)
        echo "usage: ft.sh" >&2
        exit 2
        ;;
esac
