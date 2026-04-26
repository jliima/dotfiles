#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Name:        exit-jellyfin-sofa-mode.sh
# Description: Exit sofa/TV mode and restore the normal desktop layout.
#
# Details:
#   Kills Jellyfin Media Player, switches the audio sink back to FiiO,
#   re-enables the desktop monitors, and disables the TV output.
# ------------------------------------------------------------------------------
set -euo pipefail

# ==== Configuration ====
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
Usage: $(basename "$0") [OPTIONS]

  Exit sofa/TV mode and restore the normal desktop layout.

Options:
  -h, --help    Show this help message and exit
EOF
}

# ==== Main ====
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

print_header "Exiting sofa mode"

print_info "Stopping Jellyfin Media Player"
killall jellyfinmediaplayer >/dev/null 2>&1 || true

print_info "Setting FiiO audio sink"
pactl set-default-sink "$(pactl list short sinks | awk '{print $2}' | grep 'FiiO')"

print_info "Restoring desktop display layout"
kscreen-doctor \
  "output.$MONITOR1_NAME.enable" \
  "output.$MONITOR1_NAME.primary" \
  "output.$MONITOR2_NAME.enable" \
  "output.$TV_NAME.disable" \
  "output.$MONITOR2_NAME.position.0,0" \
  "output.$MONITOR1_NAME.position.2560,0"

print_success "Desktop layout restored"
