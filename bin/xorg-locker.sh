#!/usr/bin/env bash

set -euo pipefail

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] <file-or-directory>

Lock screen with an optional image effect.

Arguments:
  <file-or-directory>    Image file or directory containing images

Options:
  -e <number>    Select effect number (0-7)
                 0 = No effect
                 1 = Frosted blur
                 2 = Cinematic vignette
                 3 = Oil paint
                 4 = Heavy blur + noise
                 5 = Cyberpunk tint
                 6 = Glitch RGB split
                 7 = Moody desaturated film
                 If omitted, a random effect is chosen.

  -t <file>      Temporary output image file (default: /tmp/lockscreen.png)
  -w             Write image only (do not call i3lock)
  -h             Show this help message

Examples:
  $(basename "$0") ~/wallpapers
  $(basename "$0") -e 2 image.jpg
  $(basename "$0") -e 0 -w -t /tmp/test.png ~/pics
EOF
}

# Default values
EFFECT=""
WRITE_ONLY=false
TMPBG="/tmp/lockscreen.png"

# Parse options
while getopts ":e:t:wh" opt; do
    case $opt in
        e)
            EFFECT="$OPTARG"
            ;;
        t)
            TMPBG="$OPTARG"
            ;;
        w)
            WRITE_ONLY=true
            ;;
        h)
            show_help
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            show_help
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            exit 1
            ;;
    esac
done

shift $((OPTIND -1))

# Require file or directory argument
# if [[ $# -ne 1 ]]; then
#     echo "Error: You must provide a file or directory."
#     show_help
#     exit 1
# fi

INPUT="${1:-$HOME/images/wallpapers}"

# Validate effect if provided
if [[ -n "$EFFECT" ]]; then
    if ! [[ "$EFFECT" =~ ^[0-7]$ ]]; then
        echo "Error: Effect must be a number between 0 and 7."
        exit 1
    fi
else
    EFFECT=$(( RANDOM % 7 + 1 ))
fi

# Validate temporary file location
TMPDIR=$(dirname "$TMPBG")
if [[ ! -d "$TMPDIR" || ! -w "$TMPDIR" ]]; then
    echo "Error: Cannot write to directory: $TMPDIR"
    exit 1
fi

# Determine image source
if [[ -f "$INPUT" ]]; then
    IMG="$INPUT"
elif [[ -d "$INPUT" ]]; then
    IMG=$(find "${INPUT}/" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf -n1)
    if [[ -z "$IMG" ]]; then
        echo "Error: No image files found in directory."
        exit 1
    fi
else
    echo "Error: Invalid file or directory."
    exit 1
fi

RES=$(xdpyinfo | awk '/dimensions/{print $2}')

echo "Using image: $IMG"
echo "Effect: $EFFECT"
echo "Output file: $TMPBG"

# Base resize command
BASE_CMD=(magick "$IMG" -resize "$RES^" -gravity center -extent "$RES")

case $EFFECT in
    0) # No effect
        "${BASE_CMD[@]}" "$TMPBG"
        ;;
    1) # Frosted blur
        "${BASE_CMD[@]}" -blur 0x15 -brightness-contrast -15x-5 "$TMPBG"
        ;;
    2) # Cinematic vignette
        "${BASE_CMD[@]}" -modulate 100,90,80 -vignette 0x60 "$TMPBG"
        ;;
    3) # Oil paint
        "${BASE_CMD[@]}" -paint 4 -brightness-contrast -10x10 "$TMPBG"
        ;;
    4) # Heavy blur + noise
        "${BASE_CMD[@]}" -blur 0x20 -attenuate 0.3 +noise Gaussian "$TMPBG"
        ;;
    5) # Cyberpunk tint
        "${BASE_CMD[@]}" -colorspace Gray -auto-level -colorize 60,0,80 -blur 0x3 "$TMPBG"
        ;;
    6) # Glitch RGB split
        "${BASE_CMD[@]}" \
            \( +clone -channel R -roll +10+0 \) \
            \( +clone -channel G -roll -10+0 \) \
            \( +clone -channel B -roll +0+10 \) \
            -combine "$TMPBG"
        ;;
    7) # Moody desaturated film
        "${BASE_CMD[@]}" -colorspace Gray -brightness-contrast -5x20 -colorize 10,5,0 "$TMPBG"
        ;;
esac

if [[ "$WRITE_ONLY" = false ]]; then
    i3lock -n -i "$TMPBG" &
else
    echo "Write-only mode enabled. Skipping i3lock."
fi
