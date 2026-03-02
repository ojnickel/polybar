#!/bin/bash

# Dexcom polybar module - shows glucose with live-counting age timer
# Fetches from API every 5 min, updates display every second

CACHE_FILE="/tmp/dex_cache"
FETCH_SCRIPT="$HOME/.config/polybar/scripts/dexcom-fetch.sh"

# Refresh cache if missing or older than 5 min
if [[ ! -f "$CACHE_FILE" ]] || [[ $(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") )) -gt 300 ]]; then
    bash "$FETCH_SCRIPT" &>/dev/null
fi

if [[ ! -f "$CACHE_FILE" ]]; then
    echo "n/a"
    exit 0
fi

read -r VALUE TREND EPOCH_MS < "$CACHE_FILE"

if [[ -z "$VALUE" ]]; then
    echo "n/a"
    exit 0
fi

# Calculate age
NOW_MS=$(date +%s%3N)
AGE_SEC=$(( (NOW_MS - EPOCH_MS) / 1000 ))
AGE_MIN=$(( AGE_SEC / 60 ))
AGE_REM=$(( AGE_SEC % 60 ))
AGE=$(printf '%d:%02d' "$AGE_MIN" "$AGE_REM")

# Trend arrows
case "$TREND" in
    DoubleUp)       ARROW="󰁞" ;;
    SingleUp)       ARROW="󰁞" ;;
    FortyFiveUp)    ARROW="󰧆" ;;
    Flat)           ARROW="󰁕" ;;
    FortyFiveDown)  ARROW="󰦺" ;;
    SingleDown)     ARROW="󰁆" ;;
    DoubleDown)     ARROW="󰁆" ;;
    *)              ARROW="" ;;
esac

# Background color by glucose level
if   (( VALUE <= 60 )); then  BG="%{B#aa0000}"
elif (( VALUE <= 80 )); then  BG="%{B#aa6600}"
elif (( VALUE <= 99 )); then  BG="%{B#666600}"
elif (( VALUE <= 180 )); then BG="%{B#006600}"
elif (( VALUE <= 199 )); then BG="%{B#666600}"
elif (( VALUE <= 250 )); then BG="%{B#aa6600}"
else                          BG="%{B#aa0000}"
fi

echo "${BG} ${VALUE} ${ARROW} ${AGE} %{B-}"
