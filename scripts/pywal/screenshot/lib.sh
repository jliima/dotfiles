#!/usr/bin/env bash
# Shared helpers and app registry for the pywal screenshot scripts.
# Sourced by capture.sh and collage.sh, never run directly.

SCREENSHOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNIPPETS_DIR="$SCREENSHOT_DIR/snippets"
WINSHOT="$HOME/.local/bin/winshot"
DEFAULT_OUTPUT_DIR="$HOME/.cache/wal-screenshots"

# Apps that show one of the pywal per-language syntax colors (nano's
# five-language nanorc, or a generic editor scheme). Anything else in
# ALL_APPS is a theme-only app with no code snippet to open.
CODE_APPS=(nano vim kate code)
LOG_APPS=(lnav)
ALL_APPS=(nano vim kate code konsole dolphin chromium firefox obsidian spicetify claude-desktop lnav qtcreator intellij obs telegram)

snippet_for_lang() {
  case "$1" in
    java) echo "$SNIPPETS_DIR/Sample.java" ;;
    sh) echo "$SNIPPETS_DIR/sample.sh" ;;
    python) echo "$SNIPPETS_DIR/sample.py" ;;
    css) echo "$SNIPPETS_DIR/sample.css" ;;
    xml) echo "$SNIPPETS_DIR/sample.xml" ;;
    *) echo "Unknown language: $1" >&2; return 1 ;;
  esac
}

is_code_app() {
  local app="$1"
  [[ " ${CODE_APPS[*]} " == *" $app "* ]]
}

is_log_app() {
  local app="$1"
  [[ " ${LOG_APPS[*]} " == *" $app "* ]]
}

log_info() { echo -e "\033[94m$*\033[0m"; }
log_ok() { echo -e "\033[92m$*\033[0m"; }
log_warn() { echo -e "\033[93m$*\033[0m"; }
log_err() { echo -e "\033[91m$*\033[0m"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# capture <name> <size> <delay> <outfile> -- <command...>
# Wraps winshot, reporting success/failure without aborting the caller.
capture() {
  local name="$1" size="$2" delay="$3" outfile="$4"
  shift 4
  [[ "$1" == "--" ]] && shift

  log_info "  -> $name"
  if "$WINSHOT" -s "$size" -d "$delay" -o "$outfile" -- "$@" >/dev/null 2>&1; then
    log_ok "     saved $outfile"
    return 0
  else
    log_err "     failed to capture $name"
    return 1
  fi
}
