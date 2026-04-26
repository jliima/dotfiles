#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Name:        open-jellyfin-sofa-mode.sh
# Description: Launch Jellyfin Media Player in sofa/TV mode.
#
# Details:
#   Switches display output to the TV (HDMI), disables desktop monitors,
#   sets the Scarlett audio sink, stops Telegram, and launches the
#   requested Jellyfin profile (jereflix or mikaflix) in fullscreen.
#   All actions are logged to a timestamped log file.
# ------------------------------------------------------------------------------
set -euo pipefail

# ==== Configuration ====
LOG_FILE="$HOME/.local/state/open-jellyfin-sofa-mode.log"
JEREFLIX_LAUNCHER="$HOME/.local/bin/jmp-jereflix"
MIKAFLIX_LAUNCHER="$HOME/.local/bin/jmp-mikaflix"
TV_NAME="HDMI-A-1"
MONITOR1_NAME="DP-1"
MONITOR2_NAME="DP-2"

# ==== Colors ====
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
BOLD='\033[1m'
NC='\033[0m'

# ==== Output helpers ====
print_header()  { echo -e "${BOLD}${MAGENTA}>>> $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error()   { echo -e "${RED}✗ $1${NC}"; }
print_info()    { echo -e "${BLUE}> $1${NC}"; }
print_warn()    { echo -e "${YELLOW}! $1${NC}"; }

# ==== Functions ====
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] {jereflix|mikaflix}

  Launch Jellyfin Media Player in sofa/TV mode.

Options:
  -h, --help    Show this help message and exit
EOF
}

log() {
  local msg="$1"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  printf '[%s] %s\n' "$ts" "$msg" | tee -a "$LOG_FILE"
}

# ==== Main ====
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

mkdir -p "$(dirname "$LOG_FILE")"

if [ "${1:-}" = "" ]; then
  print_error "Missing argument. Usage: $0 {jereflix|mikaflix}"
  exit 1
fi

case "$1" in
  jereflix)
    launcher="$JEREFLIX_LAUNCHER"
    ;;
  mikaflix)
    launcher="$MIKAFLIX_LAUNCHER"
    ;;
  *)
    print_error "Invalid argument '$1'. Use 'jereflix' or 'mikaflix'."
    exit 1
    ;;
esac

print_header "Sofa mode"

log "Setting display layout for sofa mode."
print_info "Switching display to TV"
kscreen-doctor \
  "output.$TV_NAME.enable" \
  "output.$TV_NAME.primary" \
  "output.$MONITOR1_NAME.disable" \
  "output.$MONITOR2_NAME.disable"

log "Selecting Scarlett audio sink."
print_info "Setting Scarlett audio sink"
scarlett_sink="$(pactl list short sinks | awk '{print $2}' | grep 'Scarlett' | head -n 1)"
if [ -z "$scarlett_sink" ]; then
  print_error "Scarlett sink not found."
  exit 1
fi
pactl set-default-sink "$scarlett_sink"

log "Stopping Telegram."
print_info "Stopping Telegram"
killall Telegram >/dev/null 2>&1 || true

if pgrep -f jellyfinmediaplayer >/dev/null; then
  print_warn "Jellyfin Media Player is already running; skipping launch."
  log "Jellyfin Media Player is already running; skipping launch."
else
  log "Launching $1 in sofa mode."
  print_info "Launching $1 in sofa mode"
  "$launcher" --tv --fullscreen &
fi

log "Done."
print_success "Done"

