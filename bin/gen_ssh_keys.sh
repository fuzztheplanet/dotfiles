#!/usr/bin/env bash

TMP_DIR="$(mktemp -d)"
KEY_COMMENT="aloha"

echo "Using directory ${TMP_DIR}"

while true
do
    ssh-keygen -t ed25519 -f "${TMP_DIR}/newkey" -C "${KEY_COMMENT}" -N '' 2>/dev/null 1>&2;
    if grep -q -e 'cool ' -e 'c00l ' "${TMP_DIR}/newkey.pub"; then
        echo "Found pattern. Stopping key generation."
        cat "${TMP_DIR}/newkey.pub"
        echo "[!] Don't forget to securely copy and remove the private key!"
        exit 0
    else
        rm "${TMP_DIR}/newkey" "${TMP_DIR}/newkey.pub"
    fi
done
