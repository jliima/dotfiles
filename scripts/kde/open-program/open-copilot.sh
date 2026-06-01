#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Name:        open-copilot.sh
# Description: Open GitHub Copilot in Konsole using a user based on activity.
#
# Details:
#   Detects the current KDE Plasma activity and selects the Copilot user based
#   on the mapping in $HOME/dotfiles/.env/copilot. The script uses COPILOT_HOME
#   to isolate credentials per user. A manual user override can be provided
#   with -u/--user, including the aliases "default" and "work". Any additional
#   flags are passed through to the Copilot CLI.
#
#   First-time setup:
#   - Create $HOME/dotfiles/.env/copilot with WORK_USER and DEFAULT_USER.
#   - Run the script once per profile to log in (e.g., with --user default
#     or --user work). This writes credentials under ~/.copilot-<user> via
#     COPILOT_HOME. Repeat after clearing those directories or changing users.
# ------------------------------------------------------------------------------
set -euo pipefail

# ==== Configuration ====
COPILOT_BIN="$HOME/bin/copilot"
KONSOLE_COLUMNS=120
KONSOLE_ROWS=60
WORK_USER=""
DEFAULT_USER=""
MANUAL_USER=""
INVERT_ACTIVITY=false
ENV_DIR="$HOME/dotfiles/.env"
COPILOT_ENV_FILE="$ENV_DIR/copilot"
COPILOT_HOME_BASE="$HOME/.copilot"
COPILOT_ARGS=()
ENV_LOADED=false

# ==== Colors ====
# shellcheck disable=SC2034
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
BOLD='\033[1m'
NC='\033[0m'

: "${CYAN}"
: "${GREEN}"
: "${YELLOW}"
: "${BLUE}"
: "${MAGENTA}"
: "${BOLD}"

print_error()   { echo -e "${RED}✗ $1${NC}"; }

# ==== Functions ====
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

  Open GitHub Copilot in Konsole using a user based on the current KDE Plasma
  activity.

Options:
  -h, --help           Show this help message and exit
  -u, --user USER      Override the user for this launch
  --invert             Swap default/work selection for activity-based launch

  Additional flags are passed through to the Copilot CLI.

Notes:
  User mapping is loaded from \$HOME/dotfiles/.env/copilot.
  The selected user is applied by setting COPILOT_HOME so each user can have
  separate Copilot credentials stored under ~/.copilot-<user>.
EOF
}

load_env() {
  if [ ! -f "$COPILOT_ENV_FILE" ]; then
    return 1
  fi

  # shellcheck disable=SC1090
  source "$COPILOT_ENV_FILE"

  if [ -z "${WORK_USER:-}" ] || [ -z "${DEFAULT_USER:-}" ]; then
    print_error "WORK_USER and DEFAULT_USER must be set in $COPILOT_ENV_FILE"
    return 1
  fi

  return 0
}

get_copilot_user() {
  local current_activity

  current_activity=$(plasma-activities-cli6 --current-activity | awk '{print $2}')

  if [ "$current_activity" = "Work" ]; then
    if [ "$INVERT_ACTIVITY" = true ]; then
      echo "$DEFAULT_USER"
    else
      echo "$WORK_USER"
    fi
  else
    if [ "$INVERT_ACTIVITY" = true ]; then
      echo "$WORK_USER"
    else
      echo "$DEFAULT_USER"
    fi
  fi
}

resolve_manual_user() {
  local requested_user="$1"

  case "$requested_user" in
    default)
      echo "$DEFAULT_USER"
      ;;
    work)
      echo "$WORK_USER"
      ;;
    *)
      echo "$requested_user"
      ;;
  esac
}

get_copilot_home() {
  local selected_user="$1"

  echo "${COPILOT_HOME_BASE}-${selected_user}"
}

# ==== Main ====
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      COPILOT_ARGS+=("$@")
      break
      ;;
    -u|--user)
      if [ -z "${2:-}" ]; then
        print_error "Missing value for $1"
        usage
        exit 1
      fi
      MANUAL_USER="$2"
      shift 2
      ;;
    --invert)
      INVERT_ACTIVITY=true
      shift
      ;;
    *)
      COPILOT_ARGS+=("$1")
      shift
      ;;
  esac
done

if ! load_env; then
  if [ -z "$MANUAL_USER" ]; then
    print_error "Copilot env file not found: $COPILOT_ENV_FILE"
    exit 1
  fi
else
  ENV_LOADED=true
fi

if [ -n "$MANUAL_USER" ]; then
  if { [ "$MANUAL_USER" = "default" ] || [ "$MANUAL_USER" = "work" ]; } && [ "$ENV_LOADED" != true ]; then
    print_error "Copilot env file not found: $COPILOT_ENV_FILE"
    exit 1
  fi
  copilot_user=$(resolve_manual_user "$MANUAL_USER")
else
  copilot_user=$(get_copilot_user)
fi
copilot_home=$(get_copilot_home "$copilot_user")

if [ ! -x "$COPILOT_BIN" ]; then
  print_error "Copilot binary not found: $COPILOT_BIN"
  exit 1
fi

konsole -p TerminalColumns="$KONSOLE_COLUMNS" -p TerminalRows="$KONSOLE_ROWS" \
  -e env COPILOT_HOME="$copilot_home" "$COPILOT_BIN" "${COPILOT_ARGS[@]}" &
