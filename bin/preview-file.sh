set -euo pipefail

FILE="$1"

[ -z "$FILE" ] && exit 0


# Get MIME type
MIME=$(file --mime-type -Lb "$FILE")

case "$MIME" in

    inode/directory)
        tree -L 3 -a "$FILE"
        ;;

    # Archives
    application/x-tar)
        tar -tf "$FILE"
        ;;
    application/gzip)
        tar -tzf "$FILE"
        ;;
    application/x-bzip2)
        tar -tjf "$FILE"
        ;;
    application/x-xz)
        tar -tJf "$FILE"
        ;;
    application/zip|application/java-archive)
        unzip -l "$FILE"
        ;;
    application/x-7z-compressed)
        7z l "$FILE"
        ;;
    application/x-rar)
        unrar l "$FILE"
        ;;

    # Text files
    text/*|application/javascript|application/json|application/xml)
        bat --style=header --binary=as-text --color=always --line-range=:1000 "$FILE"
        ;;

    *)
        echo "MIME type: $MIME"
        file -b "$FILE"
        hexdump -C "$FILE" | head -n1000
        ;;
esac
