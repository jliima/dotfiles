#!/usr/bin/env bash
set -euo pipefail

log_file="$HOME/.local/state/open-jellyfin-sofa-mode.log"
mkdir -p "$(dirname "$log_file")"

log() {
  local msg="$1"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  printf '[%s] %s\n' "$ts" "$msg" | tee -a "$log_file"
}

if [ "${1:-}" = "" ]; then
  log "ERROR: Missing argument. Usage: $0 {jereflix|mikaflix}"
  exit 1
fi

case "$1" in
  jereflix)
    launcher="/home/hieroja/.local/bin/jmp-jereflix"
    ;;
  mikaflix)
    launcher="/home/hieroja/.local/bin/jmp-mikaflix"
    ;;
  *)
    log "ERROR: Invalid argument '$1'. Use 'jereflix' or 'mikaflix'."
    exit 1
    ;;
esac

TV_NAME="HDMI-A-1"
MONITOR1_NAME="DP-1"
MONITOR2_NAME="DP-2"

log "Setting display layout for sofa mode."
kscreen-doctor \
  "output.$TV_NAME.enable" \
  "output.$TV_NAME.primary" \
  "output.$MONITOR1_NAME.disable" \
  "output.$MONITOR2_NAME.disable"

log "Selecting Scarlett audio sink."
scarlett_sink="$(pactl list short sinks | awk '{print $2}' | grep 'Scarlett' | head -n 1)"
if [ -z "$scarlett_sink" ]; then
  log "ERROR: Scarlett sink not found."
  exit 1
fi
pactl set-default-sink "$scarlett_sink"

log "Stopping Telegram."
killall Telegram >/dev/null 2>&1 || true

if pgrep -f jellyfinmediaplayer >/dev/null; then
  log "Jellyfin Media Player is already running; skipping launch."
else
  log "Launching $1 in sofa mode."
  "$launcher" --tv --fullscreen &
fi

log "Done."

