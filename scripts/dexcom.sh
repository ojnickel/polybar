#!/bin/bash

# Dexcom polybar module - shows glucose with live-counting age timer
# Fetches from API every 5 min, updates display every second
# Usage: dexcom.sh [--no-time]

SHOW_TIME=true
[[ "$1" == "--no-time" ]] && SHOW_TIME=false

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

read -r VALUE TREND EPOCH_MS PREV_VALUE < "$CACHE_FILE"

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
if   (( VALUE <= 60 )); then  CLR="#aa0000"
elif (( VALUE <= 80 )); then  CLR="#aa6600"
elif (( VALUE <= 99 )); then  CLR="#666600"
elif (( VALUE <= 180 )); then CLR="#006600"
elif (( VALUE <= 199 )); then CLR="#666600"
elif (( VALUE <= 250 )); then CLR="#aa6600"
else                          CLR="#aa0000"
fi

# Difference from previous reading
DIFF=$(( VALUE - ${PREV_VALUE:-$VALUE} ))
if (( DIFF > 0 )); then
    DIFF_STR="+${DIFF}"
elif (( DIFF == 0 )); then
    DIFF_STR="0"
else
    DIFF_STR="${DIFF}"
fi

# Rounded corners using powerline glyphs
L="%{T5}%{F${CLR}}%{F-}%{T-}"
R="%{T5}%{F${CLR}}%{F-}%{T-}"

if $SHOW_TIME; then
    echo "${L}%{B${CLR}} %{T6}󹀀%{T-} ${VALUE} ${ARROW} ${DIFF_STR} ${AGE} %{B-}${R}"
else
    echo "${L}%{B${CLR}} %{T6}󹀀%{T-} ${VALUE} ${ARROW} ${DIFF_STR} %{B-}${R}"
fi
