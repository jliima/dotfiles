#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Name:        open-obsidian.sh
# Description: Open an Obsidian vault based on argument or current KDE activity.
#
# Details:
#   If a vault name is given as an argument, that vault is opened directly.
#   Otherwise the script detects the current KDE Plasma activity and opens
#   the matching vault (Work -> work-vault, School -> school-vault, etc.).
# ------------------------------------------------------------------------------
set -euo pipefail

# ==== Configuration ====
OBSIDIAN_BIN="/opt/Obsidian/obsidian"
OBSIDIAN_DIR="$HOME/Obsidian"
WORK_VAULT="$OBSIDIAN_DIR/work-vault"
SCHOOL_VAULT="$OBSIDIAN_DIR/school-vault"
DEFAULT_VAULT="$OBSIDIAN_DIR/default-vault"

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
Usage: $(basename "$0") [OPTIONS] [VAULT]

  Open an Obsidian vault. If no vault is specified, the vault is determined
  based on the current KDE Plasma activity.

Arguments:
  VAULT    Optional vault name to open. Valid values:
           - work, work-vault       Opens work-vault
           - school, school-vault   Opens school-vault
           - default, default-vault Opens default-vault

Options:
  -h, --help    Show this help message and exit

Examples:
  $(basename "$0")           # Open vault based on current activity
  $(basename "$0") work      # Open work-vault
  $(basename "$0") school    # Open school-vault
EOF
}

# ==== Main ====
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

print_header "Opening Obsidian"

if [ -n "${1:-}" ]; then
  case "$1" in
    work|work-vault)
      vault_dir="$WORK_VAULT"
      ;;
    school|school-vault)
      vault_dir="$SCHOOL_VAULT"
      ;;
    default|default-vault)
      vault_dir="$DEFAULT_VAULT"
      ;;
    *)
      print_error "Unknown vault '$1'"
      print_info "Valid vaults: work, school, default (or work-vault, school-vault, default-vault)"
      exit 1
      ;;
  esac
else
  CURRENT_ACTIVITY_RAW=$(plasma-activities-cli6 --current-activity | sed -E 's/^[^ ]+ //; s/ \([^)]*\)$//')
  CURRENT_ACTIVITY=$(echo "$CURRENT_ACTIVITY_RAW" | tr '[:upper:]' '[:lower:]')

  if [ "$CURRENT_ACTIVITY" = "work" ]; then
    vault_dir="$WORK_VAULT"
  elif [ "$CURRENT_ACTIVITY" = "school" ]; then
    vault_dir="$SCHOOL_VAULT"
  else
    vault_dir="$DEFAULT_VAULT"
  fi
fi

print_info "Vault dir: $vault_dir"

vault_name=$(basename "$vault_dir")
# URL-encode spaces (POSIX-safe)
vault_name_encoded=$(printf '%s' "$vault_name" | sed 's/ /%20/g')

"$OBSIDIAN_BIN" "obsidian://open?vault=${vault_name_encoded}" >/dev/null 2>&1 &
print_success "Obsidian launched"
