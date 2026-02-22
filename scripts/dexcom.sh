#!/bin/bash

# Reads credentials from ~/.dex (format: username:password)
# One line, colon-separated, e.g.: onickel:MyP4ssword

DEX_FILE="$HOME/.dex"

if [[ ! -f "$DEX_FILE" ]]; then
    echo " no ~/.dex"
    exit 0
fi

IFS=':' read -r USERNAME PASSWORD < "$DEX_FILE"

if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
    echo " bad ~/.dex"
    exit 0
fi

BASE_URL="https://shareous1.dexcom.com/ShareWebServices/Services"
APP_ID="d89443d2-327c-4a6f-89e5-496bbb0317db"

# Login
SESSION_ID=$(curl -sf -X POST \
    -H "Content-Type: application/json" \
    -d "{\"accountName\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"applicationId\":\"$APP_ID\"}" \
    "$BASE_URL/General/LoginPublisherAccountByName" | tr -d '"')

if [[ -z "$SESSION_ID" ]]; then
    echo " login fail"
    exit 0
fi

# Get latest glucose reading
RESPONSE=$(curl -sf -X POST \
    -H "Content-Type: application/json" \
    -d "[]" \
    "$BASE_URL/Publisher/ReadPublisherLatestGlucoseValues?sessionId=$SESSION_ID&minutes=1440&maxCount=1")

if [[ -z "$RESPONSE" || "$RESPONSE" == "[]" ]]; then
    echo " n/a"
    exit 0
fi

# Parse value and trend from JSON
VALUE=$(echo "$RESPONSE" | grep -oP '"Value"\s*:\s*\K[0-9]+' | head -1)
TREND=$(echo "$RESPONSE" | grep -oP '"Trend"\s*:\s*"\K[^"]+' | head -1)

# Trend arrows
case "$TREND" in
    DoubleUp)       ARROW="⇈" ;;
    SingleUp)       ARROW="↑" ;;
    FortyFiveUp)    ARROW="↗" ;;
    Flat)           ARROW="→" ;;
    FortyFiveDown)  ARROW="↘" ;;
    SingleDown)     ARROW="↓" ;;
    DoubleDown)     ARROW="⇊" ;;
    *)              ARROW="" ;;
esac

if [[ -n "$VALUE" ]]; then
    echo " ${VALUE} ${ARROW}"
else
    echo " n/a"
fi
