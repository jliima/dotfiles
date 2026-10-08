#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Name:        open-spotify.sh
# Description: Open Spotify, repairing the Spicetify patch and the GPU sandbox crash first when needed.
#
# Details:
#   Spotify is patched by Spicetify (theme "Themer", see ~/.config/spicetify). A Spotify update replaces the
#   patched files and leaves Spicetify's backup stale, after which `spicetify apply` only warns. This script checks
#   that before every launch and only does the (sudo) repair when something is actually off:
#
#     - Spotify package version differs from the Spicetify backup version -> reinstall Spotify (pristine files),
#       make /usr/share/spotify writable, `spicetify backup apply`. Enables the Spotify apt source if it is disabled.
#     - Spotify files are pristine (xpui.spa present) -> `spicetify backup apply`.
#     - Themer's user.css differs from the deployed one -> `spicetify apply`.
#     - Neither Apps/xpui nor Apps/xpui.spa exists (Spotify shows nothing) -> reinstall.
#     - /usr/share/spotify not writable by us -> chmod.
#
#   Spotify 1.2.90 dies with "GPU process isn't usable" on some kernels (seen on 7.0.0-38). If the first launch dies
#   that way, it is relaunched with --disable-gpu-sandbox and the flag is remembered for that kernel version.
#
#   Needing sudo from a launcher (no terminal) reopens the script in Konsole so the password can be typed.
# ------------------------------------------------------------------------------
set -euo pipefail

# ==== Configuration ====
SPOTIFY_DIR="/usr/share/spotify"
SPOTIFY_APPS="$SPOTIFY_DIR/Apps"
SPOTIFY_APT_SOURCE="/etc/apt/sources.list.d/spotify.sources"
SPOTIFY_APT_KEY="/etc/apt/keyrings/spotify.gpg"
SPICETIFY_BIN="$HOME/.spicetify/spicetify"
SPICETIFY_CONFIG="$HOME/.config/spicetify/config-xpui.ini"
THEME_CSS="$HOME/.config/spicetify/Themes/Themer/user.css"
CACHE_DIR="$HOME/.cache/open-spotify"
LOG_FILE="$CACHE_DIR/spotify.log"
GPU_FLAG="--disable-gpu-sandbox"
GPU_MARKER="$CACHE_DIR/gpu-sandbox-broken-$(uname -r)"
GPU_CRASH_TEXT="GPU process isn't usable"
STARTUP_WAIT=8   # seconds to watch the first launch for the GPU crash

# ==== Colors ====
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
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
Usage: $(basename "$0") [OPTIONS] [SPOTIFY_ARGS...]

  Open Spotify. Before launching, checks the Spicetify patch and repairs it if needed
  (asks for the sudo password when a reinstall or chmod is required).

Options:
  --check       Only print what would be repaired, change nothing
  --repair      Force the full repair (reinstall, backup, apply) even if nothing looks wrong
  -h, --help    Show this help message and exit

Other arguments (e.g. a spotify: URI) are passed to Spotify.
EOF
}

installed_version() {
  dpkg-query -W -f='${Version}' spotify-client 2>/dev/null | sed 's/^[0-9]*://'
}

backup_version() {
  awk -F'=' '/^\[Backup\]/ {in_backup=1; next} /^\[/ {in_backup=0} in_backup && $1 ~ /^version/ {gsub(/ /, "", $2); print $2}' \
    "$SPICETIFY_CONFIG" 2>/dev/null
}

spotify_pristine() { [ -e "$SPOTIFY_APPS/xpui.spa" ]; }
spotify_writable() { [ -w "$SPOTIFY_DIR" ] && [ -w "$SPOTIFY_APPS" ]; }
theme_deployed()   { cmp -s "$THEME_CSS" "$SPOTIFY_APPS/xpui/user.css"; }

# Sets the need_* flags
plan_repair() {
  need_reinstall=0; need_backup=0; need_apply=0; need_chmod=0
  if ! spotify_writable; then
    need_chmod=1
  fi
  if spotify_pristine; then
    need_backup=1
  elif [ ! -d "$SPOTIFY_APPS/xpui" ]; then
    # Neither a patched nor a pristine copy: Spotify would show nothing
    need_reinstall=1
    need_backup=1
  elif [ "$(installed_version)" != "$(backup_version)" ]; then
    # Patched files without a matching backup: only a fresh package gives Spicetify a pristine copy
    need_reinstall=1
    need_backup=1
  elif ! theme_deployed; then
    need_apply=1
  fi
  if [ "$force_repair" = 1 ]; then
    need_reinstall=1
    need_backup=1
  fi
}

print_plan() {
  print_info "Spotify $(installed_version), Spicetify backup for '$(backup_version)'"
  [ "$need_chmod" = 1 ]     && print_warn "$SPOTIFY_DIR is not writable: chmod needed"
  [ "$need_reinstall" = 1 ] && print_warn "Patched files without a matching backup: reinstall needed"
  [ "$need_backup" = 1 ]    && print_warn "Spicetify backup needed"
  [ "$need_apply" = 1 ]     && print_warn "Theme is not deployed: spicetify apply needed"
  return 0
}

# The release upgrade leaves third-party sources as "Enabled: no", and the inline key of the old source file is
# outdated (Spotify rotated to 5384CE82BA52C83A). The installed package ships the current key.
spotify_source_ok() {
  grep -qx "Signed-By: $SPOTIFY_APT_KEY" "$SPOTIFY_APT_SOURCE" 2>/dev/null &&
    ! grep -qi '^Enabled: *no' "$SPOTIFY_APT_SOURCE"
}

setup_spotify_source() {
  local key
  key=$(ls -t "$SPOTIFY_DIR"/apt-keys/*.gpg 2>/dev/null | head -1)
  [ -n "$key" ] || { print_error "No signing key in $SPOTIFY_DIR/apt-keys"; return 1; }
  sudo install -D -m 644 "$key" "$SPOTIFY_APT_KEY" || return 1
  sudo cp -n "$SPOTIFY_APT_SOURCE" "$SPOTIFY_APT_SOURCE.old" 2>/dev/null || true
  printf 'Types: deb\nURIs: https://repository.spotify.com\nSuites: stable\nComponents: non-free\nSigned-By: %s\nEnabled: yes\n' \
    "$SPOTIFY_APT_KEY" | sudo tee "$SPOTIFY_APT_SOURCE" >/dev/null
}

spotify_index_present() {
  compgen -G "/var/lib/apt/lists/*repository.spotify.com*Packages*" >/dev/null
}

# Every step must succeed before the next one: a half-done repair must never delete the patched copy
repair() {
  if [ "$need_chmod" = 1 ] || [ "$need_reinstall" = 1 ]; then
    print_info "sudo is needed"
    sudo -v || return 1
  fi

  if [ "$need_reinstall" = 1 ]; then
    if ! spotify_source_ok; then
      print_info "Setting up the Spotify apt source"
      setup_spotify_source || return 1
      sudo rm -f /var/lib/apt/lists/*repository.spotify.com*
    fi
    if ! spotify_index_present; then
      print_info "Fetching the Spotify package index"
      sudo apt-get update || return 1
      spotify_index_present || { print_error "apt update did not fetch the Spotify index"; return 1; }
    fi
    print_header "Reinstalling Spotify"
    sudo apt-get install --reinstall -y spotify-client || return 1
  fi

  if [ "$need_chmod" = 1 ] || [ "$need_reinstall" = 1 ]; then
    sudo chmod a+wr "$SPOTIFY_DIR" || return 1
    sudo chmod -R a+wr "$SPOTIFY_APPS" || return 1
  fi

  if [ "$need_reinstall" = 1 ]; then
    # Drop the old patched copy so the pristine xpui.spa is the only source (the reinstall restored it)
    spotify_pristine || { print_error "Reinstall left no xpui.spa"; return 1; }
    rm -rf "$SPOTIFY_APPS/xpui"
  fi

  if [ "$need_backup" = 1 ]; then
    print_header "Spicetify backup and apply"
    "$SPICETIFY_BIN" backup apply || return 1
  elif [ "$need_apply" = 1 ]; then
    print_header "Spicetify apply"
    "$SPICETIFY_BIN" apply --no-restart || return 1
  fi
}

launch() {
  mkdir -p "$CACHE_DIR"
  if [ -e "$GPU_MARKER" ]; then
    print_info "Launching Spotify with $GPU_FLAG"
    setsid spotify "$GPU_FLAG" "$@" >"$LOG_FILE" 2>&1 &
    print_success "Spotify launched"
    return
  fi

  print_info "Launching Spotify"
  setsid spotify "$@" >"$LOG_FILE" 2>&1 &
  local pid=$!
  local waited=0
  while [ "$waited" -lt "$STARTUP_WAIT" ]; do
    sleep 1
    waited=$((waited + 1))
    if ! kill -0 "$pid" 2>/dev/null; then
      if grep -q "$GPU_CRASH_TEXT" "$LOG_FILE"; then
        print_warn "GPU sandbox crash, relaunching with $GPU_FLAG (remembered for kernel $(uname -r))"
        touch "$GPU_MARKER"
        setsid spotify "$GPU_FLAG" "$@" >"$LOG_FILE" 2>&1 &
        print_success "Spotify launched"
      else
        print_error "Spotify exited early, see $LOG_FILE"
        exit 1
      fi
      return
    fi
  done
  print_success "Spotify launched"
}

# Keep a Konsole opened by the launcher on screen so the error can be read
pause_if_terminal() { [ -t 0 ] && read -rp "Press Enter to close" || true; }

# ==== Main ====
check_only=0
force_repair=0
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --check)   check_only=1; shift ;;
    --repair)  force_repair=1; shift ;;
    *) break ;;
  esac
done

# A running Spotify only needs the new request (URI, raise window)
if [ "$check_only" = 0 ] && [ "$force_repair" = 0 ] && pgrep -x spotify >/dev/null; then
  exec spotify "$@"
fi

print_header "Opening Spotify"
plan_repair

if [ "$check_only" = 1 ]; then
  print_plan
  if [ "$need_chmod$need_reinstall$need_backup$need_apply" = 0000 ]; then
    print_success "Nothing to repair"
  fi
  exit 0
fi

if [ "$need_chmod$need_reinstall$need_backup$need_apply" != 0000 ]; then
  print_plan
  # sudo needs a terminal for the password; from a launcher, reopen in Konsole
  if { [ "$need_chmod" = 1 ] || [ "$need_reinstall" = 1 ]; } && [ ! -t 0 ]; then
    repair_args=()
    [ "$force_repair" = 1 ] && repair_args=(--repair)
    exec konsole --separate -e "$0" "${repair_args[@]}" "$@"
  fi
  if repair; then
    print_success "Repair done"
  elif [ -d "$SPOTIFY_APPS/xpui" ] || spotify_pristine; then
    print_error "Repair failed, launching Spotify anyway"
    pause_if_terminal
  else
    print_error "Repair failed and Spotify has no interface files, not launching"
    pause_if_terminal
    exit 1
  fi
fi

launch "$@"
