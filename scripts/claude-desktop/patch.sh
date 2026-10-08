#!/usr/bin/env bash
# Installs, reverts, or reports on the claude-desktop app.asar theme patch.
#
# The patch (see claude-desktop-asar-patch.mjs) makes the app insertCSS() an
# external, user-writable theme file into every page it loads. This script
# owns the sudo side of that: keeping a pristine backup of app.asar before
# ever touching it, re-baselining that backup whenever apt has replaced
# app.asar with a newer version, and making a bad patch trivially
# reversible.
#
# Themer runs `ensure` after writing ~/.config/claude-desktop-theme/theme.css. Every apt upgrade of claude-desktop
# replaces app.asar with an unpatched copy, so `ensure` checks the patch and reinstalls it when missing.
#
# Usage:
#   patch.sh install   # (re)patch, safe to run repeatedly
#   patch.sh revert    # restore the pristine app.asar
#   patch.sh status    # report current state, no changes
#   patch.sh check     # exit 0 if the installed version is patched, no sudo
#   patch.sh ensure    # check, and install when missing (asks for the password through polkit when there is no tty)
set -euo pipefail

RESOURCES_DIR="/usr/lib/claude-desktop/resources"
ASAR="$RESOURCES_DIR/app.asar"
BACKUP="$RESOURCES_DIR/app.asar.themer-orig"
VERSION_FILE="$BACKUP.version"
# The backup from before the patch was called after Themer: still honored until the next install renames it.
LEGACY_BACKUP="$RESOURCES_DIR/app.asar.pywal-orig"
if [[ ! -f "$BACKUP" && -f "$LEGACY_BACKUP" ]]; then
  BACKUP="$LEGACY_BACKUP"
  VERSION_FILE="$BACKUP.version"
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHER="$SCRIPT_DIR/claude-desktop-asar-patch.mjs"

installed_version() {
  dpkg-query -W -f='${Version}' claude-desktop 2>/dev/null || echo "unknown"
}

backup_version() {
  [[ -f "$VERSION_FILE" ]] && cat "$VERSION_FILE" || echo ""
}

# sudo when needed; plain when already root (e.g. launched through pkexec).
as_root() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

# Patched for the installed version: the backup was taken from this version and app.asar differs from it.
is_patched() {
  [[ -f "$BACKUP" && "$(backup_version)" == "$(installed_version)" ]] && ! cmp -s "$ASAR" "$BACKUP"
}

require_asar() {
  if [[ ! -f "$ASAR" ]]; then
    echo "Error: $ASAR not found. Is claude-desktop installed?" >&2
    exit 1
  fi
}

cmd_status() {
  require_asar
  echo "installed claude-desktop version: $(installed_version)"
  if [[ -f "$BACKUP" ]]; then
    echo "pristine backup:                  $BACKUP (from version $(backup_version))"
    if cmp -s "$ASAR" "$BACKUP"; then
      echo "current app.asar:                 pristine (patch not applied)"
    else
      echo "current app.asar:                 differs from backup (patched, or manually changed)"
    fi
  else
    echo "pristine backup:                  none yet (patch never installed)"
  fi
}

cmd_check() {
  require_asar
  if is_patched; then
    echo "patched ($(installed_version))"
  else
    echo "not patched for installed version $(installed_version)"
    exit 1
  fi
}

cmd_revert() {
  require_asar
  if [[ ! -f "$BACKUP" ]]; then
    echo "Error: no backup at $BACKUP, nothing to revert." >&2
    exit 1
  fi
  echo "Restoring pristine app.asar from backup..."
  as_root cp "$BACKUP" "$ASAR"
  echo "Done. Restart claude-desktop to pick it up."
}

cmd_install() {
  require_asar
  if [[ ! -x "$(command -v node)" ]]; then
    echo "Error: node is required to build the patch." >&2
    exit 1
  fi

  if [[ "$BACKUP" == "$LEGACY_BACKUP" ]]; then
    as_root mv "$LEGACY_BACKUP" "$RESOURCES_DIR/app.asar.themer-orig"
    as_root mv "$LEGACY_BACKUP.version" "$RESOURCES_DIR/app.asar.themer-orig.version"
    BACKUP="$RESOURCES_DIR/app.asar.themer-orig"
    VERSION_FILE="$BACKUP.version"
  fi

  local current_version backed_up_version
  current_version="$(installed_version)"
  backed_up_version="$(backup_version)"

  if [[ ! -f "$BACKUP" || "$backed_up_version" != "$current_version" ]]; then
    if [[ -f "$BACKUP" ]]; then
      echo "claude-desktop was updated ($backed_up_version -> $current_version)."
      echo "The installed app.asar is a fresh, unpatched copy from that update; re-baselining the backup from it."
    else
      echo "No backup yet; treating the currently installed app.asar as pristine and backing it up."
    fi
    as_root cp "$ASAR" "$BACKUP"
    echo "$current_version" | as_root tee "$VERSION_FILE" >/dev/null
  else
    echo "Backup already matches installed version $current_version; patching from it."
  fi

  local tmp_out
  tmp_out="$(mktemp --suffix=.asar)"
  # Expand now: tmp_out is local and gone by the time the EXIT trap runs.
  trap "rm -f '$tmp_out'" EXIT

  echo "Building patched asar from the pristine backup..."
  node "$PATCHER" "$BACKUP" "$tmp_out"

  echo "Installing patched asar..."
  as_root cp "$tmp_out" "$ASAR"
  echo ""
  echo "Installed. Restart claude-desktop to pick it up."
  echo "If anything looks broken, run: $0 revert"
}

notify() {
  command -v notify-send >/dev/null && notify-send -a themer -i claude-desktop "Claude theme" "$1" || true
}

cmd_ensure() {
  if ! dpkg-query -W claude-desktop >/dev/null 2>&1; then
    echo "claude-desktop is not installed, skipping the app.asar patch."
    exit 0
  fi

  require_asar
  if is_patched; then
    echo "Reload the Claude window (Ctrl+R) or restart the app to see the new theme."
    exit 0
  fi

  echo "Installing the app.asar theme patch..."
  if sudo -n true 2>/dev/null; then
    cmd_install
  elif [[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]] && command -v pkexec >/dev/null; then
    pkexec "$(readlink -f "${BASH_SOURCE[0]}")" install
  elif [[ -t 0 ]]; then
    cmd_install
  else
    notify "app.asar is not patched. Run $0 install"
    echo "Error: cannot ask for a password here. Run: $0 install" >&2
    exit 1
  fi

  notify "Theme patch installed. Restart Claude to apply it."
}

case "${1:-install}" in
  install) cmd_install ;;
  ensure) cmd_ensure ;;
  revert) cmd_revert ;;
  status) cmd_status ;;
  check) cmd_check ;;
  *)
    echo "usage: $0 {install|revert|status|check|ensure}" >&2
    exit 2
    ;;
esac
