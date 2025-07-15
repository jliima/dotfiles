#!/bin/sh

echo "$(dbus-send --print-reply --dest=org.kde.ActivityManager /ActivityManager/Activities org.kde.ActivityManager.Activities.ActivityName string:"$(dbus-send --print-reply --dest=org.kde.ActivityManager /ActivityManager/Activities org.kde.ActivityManager.Activities.CurrentActivity | grep -oP '(?<=string ")[^"]+(?=")')" | grep -oP '(?<=string ")[^"]+(?=")')"

