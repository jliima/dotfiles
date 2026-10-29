#!/bin/bash
# ------------------------------------------------------------------------------
# Name:        open_chromium.sh
# Description: Open Chromium with a profile based on argument or current KDE activity.
#
# Details:
#   Like open_firefox.sh: if a profile name is given as an argument, Chromium
#   opens with that profile. Otherwise the script detects the current KDE Plasma
#   activity and selects the matching profile (Work, School, or default).
#   Additional arguments are passed through to Chromium. Meta+C runs this.
#
#   The profiles live side by side in ~/.config/chromium, each with its own
#   bookmarks, extensions and logins:
#
#     default  "Profile 1"  shown as Personal
#     work     "Default"    shown as Work (the profile Chromium had before)
#     school   "Profile 2"  shown as School
#
#   Missing profiles are created with their names before a start (only while
#   Chromium is not running, it rewrites Local State on exit).
#
#   Every start loads the Themer extensions (Dark Reader Themer, Stylus Themer
#   and the theme) into the profile with --load-extension, so a new profile
#   needs no "Load unpacked" by hand. They are found from the Themer clone
#   (the folder `themer` links to) and its sibling clones. The Work profile also
#   loads the Atlassian New Tab extension. Whatever else a profile has
#   (KeePassXC-Browser comes from "External Extensions") is its own.
# ------------------------------------------------------------------------------
set -euo pipefail

# ==== Configuration ====
CHROMIUM_BIN="/usr/bin/chromium"
USER_DATA="${HOME}/.config/chromium"
THEME_DIR="${USER_DATA}/themer-theme"

# ==== Colors ====
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ==== Output helpers ====
print_info() { echo -e "${BLUE}> $1${NC}"; }
print_warn() { echo -e "${YELLOW}! $1${NC}"; }

# ==== Functions ====
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [PROFILE] [CHROMIUM_ARGS...]

  Open Chromium with a specific profile. If no profile is specified, the profile
  is determined based on the current KDE Plasma activity.

Arguments:
  PROFILE    Optional profile name to use. Valid values:
             - work       Uses the Work profile
             - school     Uses the School profile
             - default    Uses the default (Personal) profile

Options:
  -h, --help    Show this help message and exit

Any additional arguments are passed directly to Chromium.

Examples:
  $(basename "$0")                    # Open based on current activity
  $(basename "$0") work               # Open with the Work profile
  $(basename "$0") school https://... # Open the School profile with a URL
  $(basename "$0") --incognito        # Incognito window, profile by activity
EOF
}

# Prints the profile folder and display name for a profile key.
profile_for() {
  case "$1" in
    work) echo "Default|Work" ;;
    school) echo "Profile 2|School" ;;
    *) echo "Profile 1|Personal" ;;
  esac
}

# Creates the profile folder and registers its name in Local State, unless Chromium is running.
ensure_profile() {
  local dir="$1" name="$2"
  pgrep -x chromium >/dev/null && return 0
  python3 - "${USER_DATA}" "${dir}" "${name}" <<'PY'
import json, os, sys
base, folder, name = sys.argv[1:]
os.makedirs(os.path.join(base, folder), exist_ok=True)
state_path = os.path.join(base, "Local State")
try:
  with open(state_path) as f:
    state = json.load(f)
except (OSError, ValueError):
  state = {}
cache = state.setdefault("profile", {}).setdefault("info_cache", {})
entry = cache.setdefault(folder, {})
if entry.get("name") != name or entry.get("is_using_default_name") is not False:
  entry["name"] = name
  entry["is_using_default_name"] = False
  with open(state_path, "w") as f:
    json.dump(state, f)
prefs_path = os.path.join(base, folder, "Preferences")
if not os.path.exists(prefs_path):
  with open(prefs_path, "w") as f:
    json.dump({"profile": {"name": name}}, f)
PY
}

# Prints the comma separated --load-extension value for a profile key.
extensions_for() {
  local key="$1" themer clone parent ext list=()
  themer=$(readlink -f "$(command -v themer || echo "${HOME}/.local/bin/themer")" 2>/dev/null || true)
  if [ -n "${themer}" ] && [ -e "${themer}" ]; then
    clone=$(dirname "${themer}")
    parent=$(dirname "${clone}")
    for ext in "${parent}/darkreader-themer/build/release/chrome-mv3" "${parent}/stylus-themer/dist-chrome-mv3"; do
      [ -f "${ext}/manifest.json" ] && list+=("${ext}")
    done
    if [ "${key}" = "work" ] && [ -f "${parent}/atlassian-newtab/manifest.json" ]; then
      list+=("${parent}/atlassian-newtab")
    fi
  fi
  [ -f "${THEME_DIR}/manifest.json" ] && list+=("${THEME_DIR}")
  local IFS=,
  echo "${list[*]}"
}

# ==== Main ====
case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
esac

key=""
case "${1:-}" in
  work | school | default)
    key="$1"
    shift
    ;;
esac

if [ -z "${key}" ]; then
  activity=$("${HOME}/scripts/kde/get_current_activity_name.sh" | tr '[:upper:]' '[:lower:]')
  case "${activity}" in
    work | school) key="${activity}" ;;
    *) key="default" ;;
  esac
  print_info "Activity detected: ${activity}"
fi

IFS='|' read -r dir name <<<"$(profile_for "${key}")"
print_info "Opening Chromium with the ${name} profile"
ensure_profile "${dir}" "${name}"

args=(--profile-directory="${dir}" --disable-features=WaylandWpColorManagerV1)
extensions=$(extensions_for "${key}")
[ -n "${extensions}" ] && args+=(--load-extension="${extensions}")

exec "${CHROMIUM_BIN}" "${args[@]}" "$@"
