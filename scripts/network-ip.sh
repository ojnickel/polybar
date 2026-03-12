#!/bin/bash

# Set your interfaces
LAN_IFACE="eno1"    # <- your Ethernet device
WIFI_IFACE="wlan0"  # <- your Wi-Fi device

# Check LAN
LAN_IP=$(ip addr show "$LAN_IFACE" | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)

if [ -n "$LAN_IP" ]; then
    echo "%{T5}%{F#44112255}%{F-}%{T-}%{B#44112255} 󰌗 $LAN_IP %{B-}%{T5}%{F#44112255}%{F-}%{T-}"
    exit
fi

# Check Wi-Fi
WIFI_IP=$(ip addr show "$WIFI_IFACE" | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)

if [ -n "$WIFI_IP" ]; then
    echo "%{T5}%{F#44112255}%{F-}%{T-}%{B#44112255}  $WIFI_IP %{B-}%{T5}%{F#44112255}%{F-}%{T-}"
    exit
fi

# No connection
echo "❌ Offline"
