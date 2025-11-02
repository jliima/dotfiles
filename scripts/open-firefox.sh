#!/bin/sh

CURRENT_ACTIVITY=$(dbus-send --print-reply --dest=org.kde.ActivityManager /ActivityManager/Activities org.kde.ActivityManager.Activities.ActivityName string:"$(dbus-send --print-reply --dest=org.kde.ActivityManager /ActivityManager/Activities org.kde.ActivityManager.Activities.CurrentActivity | grep -oP '(?<=string ")[^"]+(?=")')" | grep -oP '(?<=string ")[^"]+(?=")')

# Needed for custom Dark Reader plugin to work
export PATH="$HOME/.nvm/versions/node/v22.14.0/bin:$PATH"


if [ "$CURRENT_ACTIVITY" = "Work" ]; then
  #firefox --P "Work" "$@"
  /usr/bin/firefox --P "Work" "$@"
elif [ "$CURRENT_ACTIVITY" = "School" ]; then
  #firefox --P "Work" "$@"
  /usr/bin/firefox --P "School" "$@"
else
  /usr/bin/firefox "$@"
  #firefox "$@"
fi
