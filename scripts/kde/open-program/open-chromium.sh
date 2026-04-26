#!/bin/bash

CLASS="$1"
URL="$2"

chromium --user-data-dir=/tmp/chromium-$CLASS --new-window "$URL" &
PID=$!

# Wait for window to appear and rename it
sleep 1
wmctrl -i -r "$(wmctrl -l | grep $PID | awk '{print $1}')" -b "add,maximized_vert,maximized_horz" -N "$CLASS"

wait $PID
