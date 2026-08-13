#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Name:        get-current-activity-name.sh
# Description: Print the name of the current KDE Plasma activity (e.g. "Work",
#              "School", "Default").
#
# Details:
#   Talks to org.kde.ActivityManager directly over D-Bus via `busctl` instead
#   of shelling out to `plasma-activities-cli6`. That binary spins up a full
#   Qt/D-Bus client and has been observed to occasionally hang and spin a CPU
#   core at ~100% indefinitely (e.g. when several instances start at once, or
#   kactivitymanagerd is briefly unavailable). `busctl` is a lightweight,
#   dependency-free D-Bus client, and every call here is wrapped in `timeout`
#   as a hard ceiling so a bad D-Bus round trip can never hang the caller.
#
#   Falls back to "Default" if the activity daemon can't be reached in time.
# ------------------------------------------------------------------------------
set -euo pipefail

TIMEOUT_SECS=2
SERVICE="org.kde.ActivityManager"
OBJECT="/ActivityManager/Activities"
IFACE="org.kde.ActivityManager.Activities"

dbus_string_call() {
  # Runs a busctl call expected to return a single "s ..." reply and prints
  # just the string value. Empty output on any failure/timeout.
  timeout "$TIMEOUT_SECS" busctl --user call "$SERVICE" "$OBJECT" "$IFACE" "$@" 2>/dev/null \
    | awk -F'"' '{print $2}'
}

uuid=$(dbus_string_call CurrentActivity || true)

if [ -z "$uuid" ]; then
  echo "Default"
  exit 0
fi

name=$(dbus_string_call ActivityName s "$uuid" || true)

echo "${name:-Default}"
