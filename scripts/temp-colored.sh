#!/bin/bash

# Read temperature in °C
temp=$(cat /sys/devices/virtual/thermal/thermal_zone2/hwmon2/temp1_input)
temp=$((temp / 1000))

# Colors — insert your actual hex values here
darkgreen="#dd223322"
darkergreen="#dd1b3b1b"
orange="#dd896433"
darkorange="#ddcc5500"
darkred="#ddcc3333"

#dd Decide icon and background
if [ "$temp" -lt 30 ]; then
  icon=""
  bg="$darkgreen"
elif [ "$temp" -lt 40 ]; then
  icon=""
  bg="$darkergreen"
elif [ "$temp" -lt 50 ]; then
  icon=""
  bg="$orange"
elif [ "$temp" -lt 60 ]; then
  icon=""
  bg="$darkorange"
else
  icon=""
  bg="$darkred"
fi

#dd Output formatted with padding and background (pill shape)
echo "%{B$bg}%{F#ddffffff}  $icon ${temp}°C  %{B-}%{F-}"
