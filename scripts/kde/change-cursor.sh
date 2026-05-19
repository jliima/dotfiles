#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Name:        change-cursor.sh
# Description: Set KDE Plasma cursor theme and cursor size from the command line.
#
# Details:
#   Accepts a cursor theme name (for example: "Breeze Dark") and a size integer.
#   The script applies the selected theme, writes cursor size to kcminputrc, and
#   broadcasts reload signals so the change takes effect immediately.
# ------------------------------------------------------------------------------
set -euo pipefail

# ==== Configuration ====
CURSOR_CONFIG_FILE="kcminputrc"
CURSOR_CONFIG_GROUP="Mouse"
CURSOR_THEME_KEY="cursorTheme"
CURSOR_SIZE_KEY="cursorSize"

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
list_theme_pairs() {
  plasma-apply-cursortheme --list-themes | awk '
    /^[[:space:]]*\*/ {
      line = $0
      sub(/^[[:space:]]*\*[[:space:]]*/, "", line)
      sub(/[[:space:]]+\(Current theme for this Plasma session\)$/, "", line)
      if (match(line, /^(.*)[[:space:]]+\[([^][]+)\]$/, parts)) {
        print parts[1] "\t" parts[2]
      }
    }
  '
}

list_theme_names() {
  list_theme_pairs | awk -F '\t' '{ print $1 }'
}

resolve_theme_id() {
  local requested="$1"
  local theme_name
  local theme_id

  while IFS=$'\t' read -r theme_name theme_id; do
    if [[ "$requested" == "$theme_name" || "$requested" == "$theme_id" ]]; then
      echo "$theme_id"
      return 0
    fi
  done < <(list_theme_pairs)

  return 1
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <cursor_name> <size>

  Set KDE Plasma cursor theme and cursor size.

Options:
  -h, --help    Show this help message and exit

Installed cursor themes:
$(list_theme_names | sed 's/^/  - /')
EOF
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        print_error "Unknown option: $1"
        usage
        exit 1
        ;;
      *)
        break
        ;;
    esac
  done

  if [[ $# -ne 2 ]]; then
    print_error "Expected exactly 2 arguments: <cursor_name> <size>"
    usage
    exit 1
  fi

  local requested_theme="$1"
  local requested_size="$2"
  local theme_id

  if ! [[ "$requested_size" =~ ^[0-9]+$ ]] || [[ "$requested_size" -le 0 ]]; then
    print_error "Size must be a positive integer (received: $requested_size)"
    exit 1
  fi

  if ! theme_id="$(resolve_theme_id "$requested_theme")"; then
    print_error "Cursor theme not found: $requested_theme"
    print_info "Run '$(basename "$0") --help' to see available themes."
    exit 1
  fi

  print_header "Applying cursor settings"
  print_info "Theme: $requested_theme ($theme_id)"
  print_info "Size: $requested_size"

  plasma-apply-cursortheme "$theme_id"
  kwriteconfig6 --file "$CURSOR_CONFIG_FILE" --group "$CURSOR_CONFIG_GROUP" --key "$CURSOR_SIZE_KEY" "$requested_size"
  dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:5 int32:0
  dbus-send --session --type=signal /KWin org.kde.KWin.reloadConfig

  print_success "Cursor updated to '$requested_theme' with size $requested_size."
}

# ==== Main ====
main "$@"
