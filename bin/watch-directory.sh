#!/bin/sh

# Default events
EVENTS_TO_WATCH="modify,close_write,move,create,delete"
FIFO="/tmp/wd-$(date +%s%N)"
INOTIFY_PID=""

usage() {
    cat <<EOF
USAGE: $0 [-e events] <dir> <cmd> [args...]

    -e events   Comma-separated inotify events to watch.
                Default: modify,close_write,move,create,delete

    Executes cmd whenever dir changes (requires inotify-tools).

    Example:
        $0 /home/user/backups df -h
        $0 -e modify,create /home/user echo "changed"
EOF
}

on_exit() {
    [ -n "$INOTIFY_PID" ] && kill "$INOTIFY_PID" 2>/dev/null
    [ -p "$FIFO" ] && rm -f "$FIFO"
    exit
}

watch_dir() {
    TARGET_DIR="$1"
    shift

    mkfifo "$FIFO" || exit 1

    inotifywait -m -r -q -e "$EVENTS_TO_WATCH" "$TARGET_DIR" > "$FIFO" &
    INOTIFY_PID=$!

    trap on_exit INT TERM HUP

    while read -r _; do
        "$@"
    done < "$FIFO"

    on_exit
}

# Parse options
while getopts "e:h" opt; do
    case "$opt" in
        e) EVENTS_TO_WATCH="$OPTARG" ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

shift $((OPTIND - 1))

TARGET="$1"
shift

if [ -z "$TARGET" ] || [ ! -d "$TARGET" ] || [ $# -eq 0 ]; then
    usage
    exit 1
fi

watch_dir "$TARGET" "$@"
