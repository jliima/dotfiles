#!/usr/bin/env bash

CURRENT_ACTIVITY=$(plasma-activities-cli6 --current-activity | awk '{print $3}')

# Needed for custom Dark Reader plugin to work
export PATH="$HOME/.nvm/versions/node/v22.20.0/bin:$PATH"

if [ "$CURRENT_ACTIVITY" = "Work" ]; then
  /usr/bin/firefox --P "Work" "$@"
elif [ "$CURRENT_ACTIVITY" = "School" ]; then
  /usr/bin/firefox --P "School" "$@"
else
  /usr/bin/firefox "$@"
fi
