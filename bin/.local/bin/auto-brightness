#!/usr/bin/env bash
set -euo pipefail

# ------------------------
# CONFIG
# ------------------------
VIDEO_DEVICE="/dev/video0"
STEP=1
DELAY=0.02
MIN_BRIGHT=1
MAX_BRIGHT=100
CAL_FILE="/tmp/camera_brightness_cal"
GAMMA=0.45
VIDEO_SIZE="320x240"
CROP="50%x50%+0+0"
# ------------------------

# ------------------------
# Capture grayscale mean (0.0–1.0)
# ------------------------
capture_mean() {
    ffmpeg -y -loglevel quiet \
        -f v4l2 -video_size "$VIDEO_SIZE" \
        -i "$VIDEO_DEVICE" -frames:v 1 -f image2pipe - \
    | magick - \
        -gravity center -crop "$CROP" \
        -colorspace Gray \
        -format "%[fx:mean]" info:
}

# ------------------------
# Get ambient brightness (0–100)
# ------------------------
get_ambient_brightness() {
    local raw perc brightness

    raw=$(capture_mean)

    # Gamma + percent
    perc=$(awk -v x="$raw" -v g="$GAMMA" \
        'BEGIN { printf "%.2f", (x ^ g) * 100 }')

    # Defaults if not calibrated
    BLACK=${BLACK:-18}
    WHITE=${WHITE:-92}

    # Clamp + scale safely
    brightness=$(awk -v x="$perc" -v b="$BLACK" -v w="$WHITE" '
        BEGIN {
            if (w <= b) { print 50; exit }
            if (x < b) x = b
            if (x > w) x = w
            printf "%d", (x - b) * 100 / (w - b)
        }')

    (( brightness < MIN_BRIGHT )) && brightness=$MIN_BRIGHT
    (( brightness > MAX_BRIGHT )) && brightness=$MAX_BRIGHT

    echo "$brightness"
}

# ------------------------
# Temporary calibration
# ------------------------
calibrate_temp() {
    echo "Temporary Camera Brightness Calibration"
    echo "Step 1: Cover camera completely, then press Enter"
    read -r

    BLACK=$(capture_mean | awk -v g="$GAMMA" \
        '{ printf "%d", ($1 ^ g) * 100 }')
    echo "Measured BLACK = $BLACK"

    echo "Step 2: Point camera at bright light, then press Enter"
    read -r

    WHITE=$(capture_mean | awk -v g="$GAMMA" \
        '{ printf "%d", ($1 ^ g) * 100 }')
    echo "Measured WHITE = $WHITE"

    {
        echo "BLACK=$BLACK"
        echo "WHITE=$WHITE"
    } > "$CAL_FILE"

    echo "Calibration saved to $CAL_FILE"
}

# ------------------------
# MODE SWITCH
# ------------------------
if [[ ${1:-} == "calibrate" ]]; then
    calibrate_temp
    exit 0
fi

# ------------------------
# Load calibration
# ------------------------
if [[ -f "$CAL_FILE" ]]; then
    source "$CAL_FILE"
else
    BLACK=0
    WHITE=70
fi

# ------------------------
# BRIGHTNESS CONTROL
# ------------------------
target_percent=$(get_ambient_brightness)

current=$(brightnessctl g 2>/dev/null || echo 0)
max=$(brightnessctl m 2>/dev/null || echo 1)
current_percent=$(( current * 100 / max ))

echo "Detected brightness: ${target_percent}% (Current: ${current_percent}%)"

# Skip micro-adjustments
delta=$(( target_percent - current_percent ))
(( delta < 0 )) && delta=$(( -delta ))

if (( delta <= STEP )); then
    brightnessctl set "${target_percent}%" >/dev/null 2>&1
    exit 0
fi

# Smooth ramp
if (( current_percent < target_percent )); then
    for ((b=current_percent; b<=target_percent; b+=STEP)); do
        brightnessctl set "${b}%" >/dev/null 2>&1
        sleep "$DELAY"
    done
else
    for ((b=current_percent; b>=target_percent; b-=STEP)); do
        brightnessctl set "${b}%" >/dev/null 2>&1
        sleep "$DELAY"
    done
fi

brightnessctl set "${target_percent}%" >/dev/null 2>&1
