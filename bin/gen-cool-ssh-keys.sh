#!/usr/bin/env bash

declare -a GREP_PATTERN=("-e" "cool " "-e" "c00l ")
KEY_TYPE="ed25519"
KEY_COMMENT="aloha"

TMP_DIR="$(mktemp -d)"
echo "Using directory ${TMP_DIR}"

while true
do
    ssh-keygen -t "${KEY_TYPE}" -f "${TMP_DIR}/newkey" -C "${KEY_COMMENT}" -N '' 2>/dev/null 1>&2;
    if grep -q "${GREP_PATTERN[@]}" "${TMP_DIR}/newkey.pub"; then
        echo "Found pattern. Stopping key generation."
        cat "${TMP_DIR}/newkey.pub"
        echo "[!] Don't forget to securely copy and remove the private key!"
        exit 0
    else
        rm "${TMP_DIR}/newkey" "${TMP_DIR}/newkey.pub"
    fi
done
