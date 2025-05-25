#!/bin/sh

# USAGE:   ./grab_openbsd.sh [version] [arch] [img] [mirror]
# EXAMPLE: ./grab_openbsd.sh 6.8 i386 miniroot https://cdn.openbsd.org/pub/OpenBSD


# DEFAULTS
VERSION=${1:-"7.0"}
ARCH=${2:-"amd64"}
IMAGE=${3:-"install"}
MIRROR=${4:-"https://ftp.openbsd.org/pub/OpenBSD"}

VERSION_=$(echo "$VERSION" | tr -d '.')
BASE_URL="${MIRROR}/${VERSION}"
IMG_FILE="${IMAGE}${VERSION_}.img"
PUBKEY_FILE="openbsd-${VERSION_}-base.pub"
SHA_FILE="SHA256"
SHA_SIG_FILE="SHA256.sig"


echo -n "Downloading OpenBSD ${VERSION}... "
curl -s -OL "${BASE_URL}/${ARCH}/{$IMG_FILE,$SHA_FILE,$SHA_SIG_FILE}"
curl -s -OL "${BASE_URL}/${PUBKEY_FILE}"
echo "DONE"


echo -n "Verifying ${IMG_FILE} signature... "
if [ -n "$(command -v signify)" ]; then
    signify -Cp "${PUBKEY_FILE}" -x "${SHA_SIG_FILE}" "${IMG_FILE}" \
            > /dev/null  && echo "DONE" || echo "ERROR"

    echo "All done! :)"
    exit 0
else
    echo "'signify' utility not found, skipping."
fi


echo -n "Verifying ${IMG_FILE} checksum..."
if [ -n "$(command -v sha256sum)" ]; then
    sha256sum -c --ignore-missing "${SHA_FILE}" > /dev/null \
        && echo "DONE" || echo "ERROR"
    echo "All done! :)"
    exit 0
elif [ -n "$(command -v sha256)" ]; then
    sha256 -C "${SHA_FILE}" "${IMG_FILE}" > /dev/null \
        && echo "DONE"  || echo "ERROR"

else
    echo "No SHA256 implementation found, skipping."
fi
