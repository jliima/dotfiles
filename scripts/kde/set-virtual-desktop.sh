#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Name:        set-virtual-desktop.sh
# Description: Switches the current KWin virtual desktop by name.
#
# Details:
#   Looks up the virtual desktop ID matching the given desktop name (as
#   reported by the KWin VirtualDesktopManager D-Bus interface) and switches
#   to it by setting the "current" property on that interface.
# ------------------------------------------------------------------------------
set -euo pipefail

# ==== Configuration ====
DESKTOP_NAME="${1:-}"
KWIN_SERVICE="org.kde.KWin"
KWIN_DESKTOP_PATH="/VirtualDesktopManager"
KWIN_DESKTOP_IFACE="org.kde.KWin.VirtualDesktopManager"

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
Usage: $(basename "$0") <desktop-name>

  Switches the current KWin virtual desktop to the one matching <desktop-name>
  (e.g. "Desktop 6").

Options:
  -h, --help    Show this help message and exit
EOF
}

find_desktop_id() {
  local name="$1"
  qdbus6 --literal "$KWIN_SERVICE" "$KWIN_DESKTOP_PATH" "${KWIN_DESKTOP_IFACE}.desktops" \
    | grep -oP '\(uss\) \d+, "\K[0-9a-f-]+(?=", "'"$name"'"\])'
}

# ==== Main ====
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

if [[ -z "$DESKTOP_NAME" ]]; then
  print_error "Missing required argument: desktop-name"
  usage
  exit 1
fi

DESKTOP_ID="$(find_desktop_id "$DESKTOP_NAME")"

if [[ -z "$DESKTOP_ID" ]]; then
  print_error "Virtual desktop not found: $DESKTOP_NAME"
  exit 1
fi

qdbus6 "$KWIN_SERVICE" "$KWIN_DESKTOP_PATH" "${KWIN_DESKTOP_IFACE}.current" "$DESKTOP_ID"
print_success "Switched to virtual desktop: $DESKTOP_NAME"
