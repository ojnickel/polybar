#!/bin/bash

# Dexcom Share API (OUS / Europe)
# Reads credentials from ~/.dex (format: username:password)
# Requires Dexcom Share enabled with at least one follower

DEX_FILE="$HOME/.dex"

if [[ ! -f "$DEX_FILE" ]]; then
    echo "no ~/.dex"
    exit 0
fi

IFS=':' read -r USERNAME PASSWORD < "$DEX_FILE"

if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
    echo "bad ~/.dex"
    exit 0
fi

BASE_URL="https://shareous1.dexcom.com/ShareWebServices/Services"
APP_ID="d89443d2-327c-4a6f-89e5-496bbb0317db"

# Build JSON payloads safely (password may contain special chars)
json_auth=$(python3 -c "import json,sys; print(json.dumps({'accountName':sys.argv[1],'password':sys.argv[2],'applicationId':sys.argv[3]}))" "$USERNAME" "$PASSWORD" "$APP_ID")

# Step 1: Authenticate to get account ID
ACCOUNT_ID=$(curl -sf -X POST \
    -H "Content-Type: application/json" \
    -d "$json_auth" \
    "$BASE_URL/General/AuthenticatePublisherAccount" | tr -d '"')

if [[ -z "$ACCOUNT_ID" || "$ACCOUNT_ID" == "00000000-0000-0000-0000-000000000000" ]]; then
    echo "auth fail"
    exit 0
fi

# Step 2: Login with account ID to get session ID
json_login=$(python3 -c "import json,sys; print(json.dumps({'accountId':sys.argv[1],'password':sys.argv[2],'applicationId':sys.argv[3]}))" "$ACCOUNT_ID" "$PASSWORD" "$APP_ID")

SESSION_ID=$(curl -sf -X POST \
    -H "Content-Type: application/json" \
    -d "$json_login" \
    "$BASE_URL/General/LoginPublisherAccountById" | tr -d '"')

if [[ -z "$SESSION_ID" || "$SESSION_ID" == "00000000-0000-0000-0000-000000000000" ]]; then
    echo "login fail"
    exit 0
fi

# Step 3: Get latest glucose reading
RESPONSE=$(curl -sf -X POST \
    -H "Content-Type: application/json" \
    -d "[]" \
    "$BASE_URL/Publisher/ReadPublisherLatestGlucoseValues?sessionId=$SESSION_ID&minutes=1440&maxCount=1")

if [[ -z "$RESPONSE" || "$RESPONSE" == "[]" ]]; then
    echo "n/a"
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
    echo "${VALUE} ${ARROW}"
else
    echo "n/a"
fi
