#!/bin/bash

# Dexcom Share API fetcher - caches result to /tmp/dex_cache
# Called by dexcom.sh when cache is stale (>5 min)

DEX_FILE="$HOME/.dex"
CACHE_FILE="/tmp/dex_cache"

if [[ ! -f "$DEX_FILE" ]]; then
    exit 1
fi

IFS=':' read -r USERNAME PASSWORD < "$DEX_FILE"

if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
    exit 1
fi

BASE_URL="https://shareous1.dexcom.com/ShareWebServices/Services"
APP_ID="d89443d2-327c-4a6f-89e5-496bbb0317db"

json_auth=$(python3 -c "import json,sys; print(json.dumps({'accountName':sys.argv[1],'password':sys.argv[2],'applicationId':sys.argv[3]}))" "$USERNAME" "$PASSWORD" "$APP_ID")

ACCOUNT_ID=$(curl -sf -X POST     -H "Content-Type: application/json"     -d "$json_auth"     "$BASE_URL/General/AuthenticatePublisherAccount" | tr -d '"')

if [[ -z "$ACCOUNT_ID" || "$ACCOUNT_ID" == "00000000-0000-0000-0000-000000000000" ]]; then
    exit 1
fi

json_login=$(python3 -c "import json,sys; print(json.dumps({'accountId':sys.argv[1],'password':sys.argv[2],'applicationId':sys.argv[3]}))" "$ACCOUNT_ID" "$PASSWORD" "$APP_ID")

SESSION_ID=$(curl -sf -X POST     -H "Content-Type: application/json"     -d "$json_login"     "$BASE_URL/General/LoginPublisherAccountById" | tr -d '"')

if [[ -z "$SESSION_ID" || "$SESSION_ID" == "00000000-0000-0000-0000-000000000000" ]]; then
    exit 1
fi

RESPONSE=$(curl -sf -X POST     -H "Content-Type: application/json"     -d "[]"     "$BASE_URL/Publisher/ReadPublisherLatestGlucoseValues?sessionId=$SESSION_ID&minutes=1440&maxCount=2")

if [[ -z "$RESPONSE" || "$RESPONSE" == "[]" ]]; then
    exit 1
fi

VALUE=$(echo "$RESPONSE" | grep -oP '"Value"\s*:\s*\K[0-9]+' | head -1)
PREV_VALUE=$(echo "$RESPONSE" | grep -oP '"Value"\s*:\s*\K[0-9]+' | sed -n '2p')
TREND=$(echo "$RESPONSE" | grep -oP '"Trend"\s*:\s*"\K[^"]+'  | head -1)
EPOCH_MS=$(echo "$RESPONSE" | grep -oP '"Date\(\K[0-9]+' | head -1)

if [[ -n "$VALUE" && -n "$EPOCH_MS" ]]; then
    echo "$VALUE $TREND $EPOCH_MS ${PREV_VALUE:-$VALUE}" > "$CACHE_FILE"
fi
