#!/bin/bash
# ------------------------------------------------------------------------------
# Name:        open_spotify.sh
# Description: Open the Flatpak Spotify, keeping Spicetify up to date and applied, and working around the GPU
#              sandbox crash.
#
# Details:
#   Spotify is the Flathub com.spotify.Client (user install) patched by Spicetify (theme "Themer", see
#   ~/.config/spicetify). Before every launch this script checks the patch and only repairs what is off:
#
#     - Once a day: `spicetify update`. If Spicetify got a new version -> `spicetify restore backup apply`.
#     - Spotify files are pristine (xpui.spa present, e.g. after a Flatpak update) -> `spicetify backup apply`,
#       clearing the old backup first when it belongs to another Spotify version.
#     - Neither Apps/xpui nor Apps/xpui.spa exists (Spotify shows nothing) -> reinstall the Flatpak, then as above.
#     - Themer's user.css differs from the deployed one -> `spicetify apply`.
#
#   Spotify flags (--disable-features=WaylandWpColorManagerV1) live in
#   ~/.var/app/com.spotify.Client/config/spotify-flags.conf so the Flatpak's own launcher gets them too.
#
#   Spotify 1.2.90 dies with "GPU process isn't usable" on some kernels (seen on 7.0.0-38). If the first launch dies
#   that way, it is relaunched with --disable-gpu-sandbox and the flag is remembered for that kernel version.
# ------------------------------------------------------------------------------
set -euo pipefail

# ==== Configuration ====
FLATPAK_APP="com.spotify.Client"
SPOTIFY_DIR="${HOME}/.local/share/flatpak/app/${FLATPAK_APP}/x86_64/stable/active/files/extra/share/spotify"
SPOTIFY_APPS="${SPOTIFY_DIR}/Apps"
SPICETIFY_BIN="${HOME}/.spicetify/spicetify"
SPICETIFY_CONFIG="${HOME}/.config/spicetify/config-xpui.ini"
THEME_CSS="${HOME}/.config/spicetify/Themes/Themer/user.css"
CACHE_DIR="${HOME}/.cache/open-spotify"
LOG_FILE="${CACHE_DIR}/spotify.log"
UPDATE_MARKER="${CACHE_DIR}/spicetify-update-checked-$(date +%F)"
UPDATE_TIMEOUT=30 # seconds; offline or a slow GitHub must not block the launch
GPU_FLAG="--disable-gpu-sandbox"
GPU_MARKER="${CACHE_DIR}/gpu-sandbox-broken-$(uname -r)"
GPU_CRASH_TEXT="GPU process isn't usable"
STARTUP_WAIT=8 # seconds to watch the first launch for the GPU crash

# ==== Colors ====
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
BOLD='\033[1m'
NC='\033[0m'

# ==== Output helpers ====
print_header() { echo -e "${BOLD}${MAGENTA}>>> $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${BLUE}> $1${NC}"; }
print_warn() { echo -e "${YELLOW}! $1${NC}"; }

# ==== Functions ====
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [SPOTIFY_ARGS...]

  Open Spotify. Before launching, updates Spicetify (once a day) and checks the Spicetify patch,
  repairing it if needed.

Options:
  --check       Only print what would be repaired, change nothing
  --repair      Force the full repair (reinstall, backup, apply) even if nothing looks wrong
  -h, --help    Show this help message and exit

Other arguments (e.g. a spotify: URI) are passed to Spotify.
EOF
}

installed_version() {
  flatpak info --user "${FLATPAK_APP}" 2>/dev/null | awk '$1 == "Version:" {print $2}'
}

backup_version() {
  awk -F'=' '/^\[Backup\]/ {in_backup=1; next} /^\[/ {in_backup=0} in_backup && $1 ~ /^version/ {gsub(/ /, "", $2); print $2}' \
    "${SPICETIFY_CONFIG}" 2>/dev/null
}

spicetify_version() { "${SPICETIFY_BIN}" -v 2>/dev/null; }
spotify_pristine() { [ -e "${SPOTIFY_APPS}/xpui.spa" ]; }
theme_deployed() { cmp -s "${THEME_CSS}" "${SPOTIFY_APPS}/xpui/user.css"; }

# Sets spicetify_updated=1 when Spicetify got a new version
update_spicetify() {
  spicetify_updated=0
  [ -e "${UPDATE_MARKER}" ] && return 0
  local before
  before=$(spicetify_version)
  print_info "Checking for a Spicetify update"
  if timeout "${UPDATE_TIMEOUT}" "${SPICETIFY_BIN}" update >/dev/null 2>&1; then
    rm -f "${CACHE_DIR}"/spicetify-update-checked-*
    touch "${UPDATE_MARKER}"
  else
    print_warn "Spicetify update check failed, retrying on the next launch"
  fi
  if [ "$(spicetify_version)" != "${before}" ]; then
    print_success "Spicetify updated ${before} -> $(spicetify_version)"
    spicetify_updated=1
  fi
}

# Sets the need_* flags
plan_repair() {
  need_reinstall=0
  need_backup=0
  need_reapply=0
  need_apply=0
  if spotify_pristine; then
    need_backup=1
  elif [ ! -d "${SPOTIFY_APPS}/xpui" ]; then
    # Neither a patched nor a pristine copy: Spotify would show nothing
    need_reinstall=1
    need_backup=1
  elif [ "${spicetify_updated}" = 1 ]; then
    need_reapply=1
  elif ! theme_deployed; then
    need_apply=1
  fi
  if [ "${force_repair}" = 1 ]; then
    need_reinstall=1
    need_backup=1
  fi
}

print_plan() {
  print_info "Spotify $(installed_version), Spicetify $(spicetify_version) with backup for '$(backup_version)'"
  [ "${need_reinstall}" = 1 ] && print_warn "Spotify interface files missing: Flatpak reinstall needed"
  [ "${need_backup}" = 1 ] && print_warn "Spicetify backup needed"
  [ "${need_reapply}" = 1 ] && print_warn "Spicetify was updated: restore, backup and apply needed"
  [ "${need_apply}" = 1 ] && print_warn "Theme is not deployed: spicetify apply needed"
  return 0
}

repair() {
  if [ "${need_reinstall}" = 1 ]; then
    print_header "Reinstalling Spotify"
    flatpak install --user --reinstall -y --noninteractive flathub "${FLATPAK_APP}" || return 1
    spotify_pristine || {
      print_error "Reinstall left no xpui.spa"
      return 1
    }
  fi

  if [ "${need_backup}" = 1 ]; then
    # A backup of another Spotify version blocks `spicetify backup`; the pristine files replace it
    if [ -n "$(backup_version)" ] && [ "$(backup_version)" != "$(installed_version)" ]; then
      print_info "Clearing the Spicetify backup of Spotify $(backup_version)"
      "${SPICETIFY_BIN}" clear </dev/null || return 1
    fi
    print_header "Spicetify backup and apply"
    "${SPICETIFY_BIN}" backup apply --no-restart || return 1
  elif [ "${need_reapply}" = 1 ]; then
    print_header "Spicetify restore, backup and apply"
    "${SPICETIFY_BIN}" restore backup apply --no-restart || return 1
  elif [ "${need_apply}" = 1 ]; then
    print_header "Spicetify apply"
    "${SPICETIFY_BIN}" apply --no-restart || return 1
  fi
}

launch() {
  if [ -e "${GPU_MARKER}" ]; then
    print_info "Launching Spotify with ${GPU_FLAG}"
    setsid flatpak run "${FLATPAK_APP}" "${GPU_FLAG}" "$@" >"${LOG_FILE}" 2>&1 &
    print_success "Spotify launched"
    return
  fi

  print_info "Launching Spotify"
  setsid flatpak run "${FLATPAK_APP}" "$@" >"${LOG_FILE}" 2>&1 &
  # `flatpak run` can return while Spotify keeps running, so watch the spotify process instead of its pid
  sleep "${STARTUP_WAIT}"
  if grep -q "${GPU_CRASH_TEXT}" "${LOG_FILE}"; then
    print_warn "GPU sandbox crash, relaunching with ${GPU_FLAG} (remembered for kernel $(uname -r))"
    touch "${GPU_MARKER}"
    pkill -x spotify || true
    setsid flatpak run "${FLATPAK_APP}" "${GPU_FLAG}" "$@" >"${LOG_FILE}" 2>&1 &
  elif ! pgrep -x spotify >/dev/null; then
    print_error "Spotify exited early, see ${LOG_FILE}"
    exit 1
  fi
  print_success "Spotify launched"
}

# ==== Main ====
check_only=0
force_repair=0
while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    --check)
      check_only=1
      shift
      ;;
    --repair)
      force_repair=1
      shift
      ;;
    *) break ;;
  esac
done

# A running Spotify only needs the new request (URI, raise window)
if [ "${check_only}" = 0 ] && [ "${force_repair}" = 0 ] && pgrep -x spotify >/dev/null; then
  exec flatpak run "${FLATPAK_APP}" "$@"
fi

mkdir -p "${CACHE_DIR}"
print_header "Opening Spotify"
spicetify_updated=0
[ "${check_only}" = 0 ] && update_spicetify
plan_repair

if [ "${check_only}" = 1 ]; then
  print_plan
  if [ "${need_reinstall}${need_backup}${need_reapply}${need_apply}" = 0000 ]; then
    print_success "Nothing to repair"
  fi
  exit 0
fi

if [ "${need_reinstall}${need_backup}${need_reapply}${need_apply}" != 0000 ]; then
  print_plan
  if repair; then
    print_success "Repair done"
  elif [ -d "${SPOTIFY_APPS}/xpui" ] || spotify_pristine; then
    print_error "Repair failed, launching Spotify anyway"
  else
    print_error "Repair failed and Spotify has no interface files, not launching"
    exit 1
  fi
fi

launch "$@"
