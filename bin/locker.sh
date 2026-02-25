#!/usr/bin/env bash

RES=$(xdpyinfo | awk '/dimensions/{print $2}')
IMG="$(find ~/images/wallpapers/ | sort -R | head -n1)"
TMPBG="/tmp/lockscreen.png"

effect=$((RANDOM % 5))
echo "${effect}"

case $effect in
    0) # Frosted blur
        magick "$IMG" -resize "$RES^" -gravity center -extent "$RES" \
               -blur 0x15 -brightness-contrast -15x-5 "$TMPBG"
        ;;
    1) # Cinematic vignette
        magick "$IMG" -resize "$RES^" -gravity center -extent "$RES" \
               -modulate 100,90,80 -vignette 0x60 "$TMPBG"
        ;;
    2) # Oil paint
        magick "$IMG" -resize "$RES^" -gravity center -extent "$RES" \
               -paint 4 -brightness-contrast -10x10 "$TMPBG"
        ;;
    3) # Heavy blur + noise
        magick "$IMG" -resize "$RES^" -gravity center -extent "$RES" \
               -blur 0x20 -attenuate 0.3 +noise Gaussian "$TMPBG"
        ;;
    4) # Cyberpunk tint
        magick "$IMG" -resize "$RES^" -gravity center -extent "$RES" \
               -colorspace Gray -auto-level -colorize 60,0,80 -blur 0x3 "$TMPBG"
        ;;
    5) # Glitch RGB split
        magick "$IMG" -resize "$RES^" -gravity center -extent "$RES" \
                \( +clone -channel R -roll +10+0 \) \
                \( +clone -channel G -roll -10+0 \) \
                \( +clone -channel B -roll +0+10 \) \
                -combine "$TMPBG"
        ;;
    6) # Moody desaturated film
        magick "$IMG" -resize "$RES^" -gravity center -extent "$RES" \
                -colorspace Gray -brightness-contrast -5x20 \
                -colorize 10,5,0 "$TMPBG"
        ;;
esac

i3lock -i "$TMPBG"
