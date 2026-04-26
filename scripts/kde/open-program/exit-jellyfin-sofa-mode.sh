#!/usr/bin/env bash
set -euo pipefail

TV_NAME="HDMI-A-1"
MONITOR1_NAME="DP-1"
MONITOR2_NAME="DP-2"

killall jellyfinmediaplayer > /dev/null 2>&1

pactl set-default-sink "$(pactl list short sinks | awk '{print $2}' | grep 'FiiO')"

kscreen-doctor \
    "output.$MONITOR1_NAME.enable" \
    "output.$MONITOR1_NAME.primary" \
    "output.$MONITOR2_NAME.enable" \
    "output.$TV_NAME.disable" \
    "output.$MONITOR2_NAME.position.0,0" \
    "output.$MONITOR1_NAME.position.2560,0"
