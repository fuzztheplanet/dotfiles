#!/bin/sh

EVENTS_TO_WATCH="modify,close_write,move,create,delete"
FIFO="/tmp/wd-$(date +%s%N)"

usage() {

    echo "USAGE: $0 <dir> <cmd>"
    echo "    Executes cmd whenever dir changes (requires inotifywait)."
    echo "    Ex: $0 /home/user/backups df -h"
}


on_exit() {

    kill "$INOTIFY_PID"
    rm "$FIFO"
    exit
}


watch_dir() {

    mkfifo "$FIFO"
    inotifywait -m -r -q -e "$EVENTS_TO_WATCH" "$1" > "$FIFO" &
    INOTIFY_PID=$!
    trap "on_exit" 2 3 15

    while read -r file; do "$2"; done < "$FIFO"
    on_exit
}


TARGET="$1"
shift

[ ! -d "$TARGET" ] && usage && exit 0
watch_dir "$TARGET" "$@"
