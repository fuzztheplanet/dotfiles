#!/usr/bin/env bash


# USAGE: start_tmux.sh
# This script used dmenu



new_session_id() { #dirty

    # If there are already other "views", spawn a new one with incremented index
    if grep -q -i "#" <<< "${1}"; then

        local base="${1%#*}"
        local old_id="${1#*#}"
        local new_id=$((old_id + 1))
        echo "${base}#${new_id}"

    else # No other views for a given session, create the first one
        echo "${1}#1"
    fi
}


all_sessions=$(tmux ls | cut -d':' -f1 | sort -n -t '#' -k 2)
base_sessions=$(grep -v -E '.*#[0-9]+' <<< ${all_sessions})
selected_session=$(echo "${base_sessions}" | dmenu -p "spawn tmux> ")

[[ "$?" -ne 0 ]] && { echo "User aborted!"; exit 0; }

echo "Got selected session: ${selected_session}"

# If selected base session doesn't exist, spawn one and assign a new group
if ! grep -q -i ${selected_session} <<< ${all_sessions}; then

    echo "Spawing new base session: ${selected_session}"
    i3-sensible-terminal \
        -e tmux new-session -s ${selected_session} -t ${selected_session}

else # Base session exists, spawn another "view" in the group
    if [[ -z "${TMUX}" ]]; then # Only if not already in a tmux session

        last_session="$(grep ${selected_session} <<< ${all_sessions} | tail -1)"
        echo "Got last session: ${last_session}"
        new_id="$(new_session_id ${last_session})"
        echo "Spawing new view: ${new_id}"
        i3-sensible-terminal \
            -e tmux new-session -s ${new_id} -t ${selected_session}
    fi
fi
