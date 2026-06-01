#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Name:        open-firefox.sh
# Description: Open Firefox with a profile based on argument or current KDE activity.
#
# Details:
#   If a profile name is given as an argument, Firefox opens with that profile.
#   Otherwise the script detects the current KDE Plasma activity and selects
#   the matching profile (Work, School, or default). Additional arguments
#   are passed through to Firefox.
# ------------------------------------------------------------------------------
set -euo pipefail

# ==== Configuration ====
FIREFOX_BIN="/usr/bin/firefox"
NODE_PATH="$HOME/.nvm/versions/node/v22.20.0/bin"

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
Usage: $(basename "$0") [OPTIONS] [PROFILE] [FIREFOX_ARGS...]

  Open Firefox with a specific profile. If no profile is specified, the profile
  is determined based on the current KDE Plasma activity.

Arguments:
  PROFILE    Optional profile name to use. Valid values:
             - work       Uses Work profile
             - school     Uses School profile
             - default    Uses default profile (no --P flag)

Options:
  -h, --help    Show this help message and exit

Any additional arguments are passed directly to Firefox.

Examples:
  $(basename "$0")                    # Open based on current activity
  $(basename "$0") work               # Open with Work profile
  $(basename "$0") school             # Open with School profile
  $(basename "$0") work https://...   # Open Work profile with URL
EOF
}

# ==== Main ====
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

# Needed for custom Dark Reader plugin to work
export PATH="$NODE_PATH:$PATH"

case "${1:-}" in
  work)
    shift
    print_info "Opening Firefox with Work profile"
    "$FIREFOX_BIN" --P "Work" "$@"
    exit 0
    ;;
  school)
    shift
    print_info "Opening Firefox with School profile"
    "$FIREFOX_BIN" --P "School" "$@"
    exit 0
    ;;
  default)
    shift
    print_info "Opening Firefox with default profile"
    "$FIREFOX_BIN" "$@"
    exit 0
    ;;
esac

# No profile argument — use activity-based detection
CURRENT_ACTIVITY_RAW=$(plasma-activities-cli6 --current-activity | awk '{print $2}')
CURRENT_ACTIVITY=$(echo "$CURRENT_ACTIVITY_RAW" | tr '[:upper:]' '[:lower:]')

if [ "$CURRENT_ACTIVITY" = "work" ]; then
  print_info "Activity detected: Work"
  "$FIREFOX_BIN" --P "Work" "$@"
elif [ "$CURRENT_ACTIVITY" = "school" ]; then
  print_info "Activity detected: School"
  "$FIREFOX_BIN" --P "School" "$@"
else
  print_info "Activity detected: Default"
  "$FIREFOX_BIN" "$@"
fi
