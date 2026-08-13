#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Name:        set-activity.sh
# Description: Switches the current KDE Plasma activity by name.
#
# Details:
#   Looks up the activity ID matching the given activity name (as reported by
#   `plasma-activities-cli6 --list-activities`) and switches to it via
#   `plasma-activities-cli6 --set-current-activity`.
# ------------------------------------------------------------------------------
set -euo pipefail

# ==== Configuration ====
ACTIVITY_NAME="${1:-}"

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
Usage: $(basename "$0") <activity-name>

  Switches the current KDE Plasma activity to the one matching <activity-name>.

Options:
  -h, --help    Show this help message and exit
EOF
}

find_activity_id() {
  local name="$1"
  timeout 5 plasma-activities-cli6 --list-activities | sed -n -E "s/^([0-9a-f-]+) ${name} \(.*\)\$/\1/p" | head -n1
}

# ==== Main ====
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

if [[ -z "$ACTIVITY_NAME" ]]; then
  print_error "Missing required argument: activity-name"
  usage
  exit 1
fi

ACTIVITY_ID="$(find_activity_id "$ACTIVITY_NAME")"

if [[ -z "$ACTIVITY_ID" ]]; then
  print_error "Activity not found: $ACTIVITY_NAME"
  exit 1
fi

timeout 5 plasma-activities-cli6 --set-current-activity "$ACTIVITY_ID"
print_success "Switched to activity: $ACTIVITY_NAME"
