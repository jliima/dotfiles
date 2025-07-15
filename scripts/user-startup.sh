#!/usr/bin/env bash
# This script should continue on errors
# set -e
set -u

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_DIR="$(dirname "${SCRIPT_DIR}")"

#if command -v kwallet-query &> /dev/null; then
#  kwallet-query -l kdewallet > /dev/null
#fi


#echo "Starting SSH agent configuration script."
#SETUP_AGENT="${REPO_DIR}/ssh/setup_agent.sh"
#if [ -f "${SETUP_AGENT}" ]; then
#  "${SETUP_AGENT}" private-scripts
#fi


# Syncthing and cloud services should be started as early as possible to ensure
# that the user does not modify files before they are synced.
if command -v syncthing >/dev/null 2>&1; then
  syncthing --no-browser &
fi

#if command -v telegram-desktop >/dev/null 2>&1; then
#  echo "Starting Telegram"
#  telegram-desktop -startintray &
#fi

