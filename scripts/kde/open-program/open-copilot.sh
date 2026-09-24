#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Name:        open-copilot.sh
# Description: Open GitHub Copilot CLI in Konsole.
#
# Details:
#   Launches the Copilot CLI in a sized Konsole window using the default
#   ~/.copilot home. Switch GitHub accounts inside the CLI with /user. Any
#   flags are passed through to the Copilot CLI.
# ------------------------------------------------------------------------------
set -euo pipefail

# ==== Configuration ====
COPILOT_BIN="$HOME/bin/copilot"
KONSOLE_COLUMNS=120
KONSOLE_ROWS=60
COPILOT_ARGS=()

# ==== Colors ====
RED='\033[1;31m'
NC='\033[0m'

print_error()   { echo -e "${RED}✗ $1${NC}"; }

# ==== Functions ====
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

  Open GitHub Copilot CLI in Konsole.

Options:
  -h, --help           Show this help message and exit

  Additional flags are passed through to the Copilot CLI.
EOF
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
    *)
      COPILOT_ARGS+=("$1")
      shift
      ;;
  esac
done

if [ ! -x "$COPILOT_BIN" ]; then
  print_error "Copilot binary not found: $COPILOT_BIN"
  exit 1
fi

konsole -p TerminalColumns="$KONSOLE_COLUMNS" -p TerminalRows="$KONSOLE_ROWS" \
  -e "$COPILOT_BIN" "${COPILOT_ARGS[@]}" &
