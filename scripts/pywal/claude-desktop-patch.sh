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
# Usage:
#   claude-desktop-patch.sh install   # (re)patch, safe to run repeatedly
#   claude-desktop-patch.sh revert    # restore the pristine app.asar
#   claude-desktop-patch.sh status    # report current state, no changes
set -euo pipefail

RESOURCES_DIR="/usr/lib/claude-desktop/resources"
ASAR="$RESOURCES_DIR/app.asar"
BACKUP="$RESOURCES_DIR/app.asar.pywal-orig"
VERSION_FILE="$RESOURCES_DIR/app.asar.pywal-orig.version"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHER="$SCRIPT_DIR/claude-desktop-asar-patch.mjs"

installed_version() {
  dpkg-query -W -f='${Version}' claude-desktop 2>/dev/null || echo "unknown"
}

backup_version() {
  [[ -f "$VERSION_FILE" ]] && cat "$VERSION_FILE" || echo ""
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

cmd_revert() {
  require_asar
  if [[ ! -f "$BACKUP" ]]; then
    echo "Error: no backup at $BACKUP, nothing to revert." >&2
    exit 1
  fi
  echo "Restoring pristine app.asar from backup..."
  sudo cp "$BACKUP" "$ASAR"
  echo "Done. Restart claude-desktop to pick it up."
}

cmd_install() {
  require_asar
  if [[ ! -x "$(command -v node)" ]]; then
    echo "Error: node is required to build the patch." >&2
    exit 1
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
    sudo cp "$ASAR" "$BACKUP"
    echo "$current_version" | sudo tee "$VERSION_FILE" >/dev/null
  else
    echo "Backup already matches installed version $current_version; patching from it."
  fi

  local tmp_out
  tmp_out="$(mktemp --suffix=.asar)"
  trap 'rm -f "$tmp_out"' EXIT

  echo "Building patched asar from the pristine backup..."
  node "$PATCHER" "$BACKUP" "$tmp_out"

  echo "Installing patched asar..."
  sudo cp "$tmp_out" "$ASAR"
  echo ""
  echo "Installed. Restart claude-desktop to pick it up."
  echo "If anything looks broken, run: $0 revert"
}

case "${1:-install}" in
  install) cmd_install ;;
  revert) cmd_revert ;;
  status) cmd_status ;;
  *)
    echo "usage: $0 {install|revert|status}" >&2
    exit 2
    ;;
esac
